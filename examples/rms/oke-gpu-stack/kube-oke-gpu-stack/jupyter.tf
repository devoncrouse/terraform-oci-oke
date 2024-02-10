# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  jupyter_name     = "jupyter"
  jupyter_name_gpu = format("%s-gpu", local.jupyter_name)
  jupyter_image    = "ord.ocir.io/hpc_limited_availability/oke/jupyter:1.0.0-10"
  jupyter_labels = tomap({
    "app.kubernetes.io/name"    = local.jupyter_name
    "app.kubernetes.io/version" = "1.0"
    "app.kubernetes.io/part-of" = "oke-gpu-stack"
  })
  instances = {
    (local.jupyter_name) = {
      requests = tomap({ cpu = "1", memory = "3Gi", "ephemeral-storage" = "5Gi" })
      limits   = tomap({ "ephemeral-storage" = "16Gi" })
      labels   = local.jupyter_labels
    }
  }

  jupyter_config_name = "jupyter_server_config.py"
  jupyter_config = templatefile(
    format("%v/templates/%v.tftpl", path.module, local.jupyter_config_name),
    {}
  )

  ipynb_files = { "empty" = "" }
}

resource "kubernetes_namespace_v1" "jupyter" {
  metadata {
    name = var.jupyter_namespace
    labels = {
      istio-injection               = "enabled"
      "kubernetes.io/metadata.name" = var.jupyter_namespace
      "kiali.io/member-of"          = "istio-system"
    }
  }
}

resource "kubernetes_config_map_v1" "jupyter" {
  depends_on = [kubernetes_namespace_v1.jupyter]
  metadata {
    name      = "jupyter-config"
    namespace = var.jupyter_namespace
    labels    = local.jupyter_labels
  }
  binary_data = {
    (local.jupyter_config_name) = base64encode(local.jupyter_config)
  }
}

resource "kubernetes_service_account_v1" "jupyter" {
  depends_on = [kubernetes_namespace_v1.jupyter]
  metadata {
    name      = local.jupyter_name
    namespace = var.jupyter_namespace
  }
  secret { name = local.jupyter_name }
}

resource "kubernetes_cluster_role_binding_v1" "jupyter" {
  depends_on = [kubernetes_service_account_v1.jupyter]
  metadata {
    name = format("%s-default", local.jupyter_name)
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.jupyter_name
    namespace = var.jupyter_namespace
  }
}

resource "kubernetes_config_map_v1" "ipynb_examples" {
  depends_on = [kubernetes_namespace_v1.jupyter]
  metadata {
    name      = "oke-examples-ipynb"
    namespace = var.jupyter_namespace
    labels    = local.jupyter_labels
  }
  binary_data = { for k, v in local.ipynb_files : k => base64encode(v) }
}

resource "kubernetes_stateful_set_v1" "jupyter_notebook" {
  depends_on = [
    kubernetes_namespace_v1.jupyter,
    kubernetes_cluster_role_binding_v1.jupyter,
  ]
  for_each         = local.instances
  wait_for_rollout = false
  metadata {
    name      = each.key
    namespace = var.jupyter_namespace
    labels    = each.value.labels
  }
  spec {
    replicas     = 1
    service_name = each.key
    selector {
      match_labels = each.value.labels
    }

    template {
      metadata {
        labels = each.value.labels
      }
      spec {
        service_account_name             = local.jupyter_name
        automount_service_account_token  = true
        termination_grace_period_seconds = 5
        security_context {
          fs_group     = 0
          run_as_user  = 0
          run_as_group = 0
        }

        volume {
          name = "shm"
          empty_dir {
            medium     = "Memory"
            size_limit = "32Gi"
          }
        }
        # TODO Dynamic w/ enablement
        volume {
          name = "fss"
          persistent_volume_claim { claim_name = "oke-fss" }
        }
        volume {
          name = "examples"
          config_map { name = "oke-examples-ipynb" }
        }
        volume {
          name = "jupyter-config"
          config_map { name = "jupyter-config" }
        }

        dynamic "toleration" {
          for_each = lookup(each.value, "tolerations", [])
          content {
            key      = lookup(toleration.value, "key", null)
            operator = lookup(toleration.value, "operator", null)
          }
        }

        container {
          name  = "jupyter"
          image = lookup(each.value, "image", local.jupyter_image)
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "examples"
            mount_path = "/mnt/examples"
          }
          volume_mount {
            name       = "jupyter-config"
            mount_path = "/etc/jupyter"
          }
          volume_mount {
            name       = "shm"
            mount_path = "/dev/shm"
          }
          # TODO Dynamic w/ enablement
          volume_mount {
            name              = "fss"
            mount_path        = "/mnt/fss"
            mount_propagation = "HostToContainer"
          }
          port {
            container_port = 80
            name           = "http2-web"
          }
          startup_probe {
            http_get {
              path = "/api"
              port = "http2-web"
            }
            period_seconds    = 3
            failure_threshold = 300
          }
          liveness_probe {
            http_get {
              path = "/api"
              port = "http2-web"
            }
            period_seconds = 3
          }
          command = ["bash"]
          args = ["-c", <<-EOT
              mkdir -p /mnt/fss/oci-hpc-oke/
              cp -urv /mnt/examples/* /mnt/fss/oci-hpc-oke/
              python -Xfrozen_modules=off -m jupyterlab -y \
                --autoreload --no-browser --allow-root \
                --JupyterApp.config_file=$JUPYTER_CONFIG \
                --Application.log_level=DEBUG || sleep 1800
            EOT
          ]
          env {
            name = "POD_IP"
            value_from {
              field_ref { field_path = "status.podIP" }
            }
          }
          env {
            name = "HOST_IP"
            value_from {
              field_ref { field_path = "status.hostIP" }
            }
          }
          env {
            name = "NODE_NAME"
            value_from {
              field_ref { field_path = "spec.nodeName" }
            }
          }
          env {
            name = "NAMESPACE"
            value_from {
              field_ref { field_path = "metadata.namespace" }
            }
          }
          env {
            name = "SVC_ACCT_NAME"
            value_from {
              field_ref { field_path = "spec.serviceAccountName" }
            }
          }
          env {
            name  = "JUPYTER_PORT"
            value = "80"
          }
          env {
            name  = "JUPYTER_PORT_RETRIES"
            value = "0"
          }
          env {
            name  = "JUPYTER_CONFIG"
            value = "/etc/jupyter/jupyter_server_config.py"
          }
          env {
            name  = "OCI_CLI_AUTO_PROMPT"
            value = "False"
          }
          resources {
            requests = each.value.requests
            limits   = each.value.limits
          }
        }
      }
    }
  }
}
