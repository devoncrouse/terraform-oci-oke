# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  gpu_operator_name = "gpu-operator"
  gpu_operator_labels = {
    app                         = "gpu-operator"
    "app.kubernetes.io/name"    = "gpu-operator"
    "app.kubernetes.io/part-of" = "oke-gpu-stack"
    "app.kubernetes.io/version" = "23"
    version                     = "23"
  }

  gpu_operator_helm_values = {
    operator = {
      defaultRuntime = "crio"
      annotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "metrics"
        "prometheus.io/path"   = "/metrics"
      }
    }
    driver = {
      enabled         = true
      version         = "535.129.03"
      rdma            = { enabled = true, useHostMofed = true }
      nvidiaDriverCRD = { enabled = true, deployDefaultCR = true }
    }
    devicePlugin = {
      enabled = true
      config = {
        create = true
      }
    }
    dcgmExporter = {
      serviceMonitor = {
        enabled  = true
        interval = "5s"
      }
    }
    vgpuManager = { enabled = false }
  }

  gpu_operator_helm_values_yaml = jsonencode(local.gpu_operator_helm_values)
}

resource "kubernetes_namespace_v1" "gpu" {
  metadata {
    name = var.gpu_namespace
    labels = {
      "istio-injection"             = "disabled"
      "kubernetes.io/metadata.name" = var.gpu_namespace
      "kiali.io/member-of"          = "istio-system"
    }
  }
}

resource "helm_release" "gpu_operator" {
  depends_on = [
    helm_release.prometheus,
    helm_release.network_operator,
    kubernetes_namespace_v1.gpu,
  ]
  chart            = local.gpu_operator_name
  name             = local.gpu_operator_name
  namespace        = var.gpu_namespace
  repository       = "https://helm.ngc.nvidia.com/nvidia"
  version          = "23.9.1"
  values           = [local.gpu_operator_helm_values_yaml]
  create_namespace = false
  force_update     = true
  max_history      = 1
}

