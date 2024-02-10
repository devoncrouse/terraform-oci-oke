# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  grafana_version = "10.2"
  grafana_labels = merge(local.monitoring_labels, {
    app                                   = "grafana"
    "app.kubernetes.io/name"              = "grafana"
    "service.istio.io/canonical-name"     = "grafana"
    "app.kubernetes.io/part-of"           = "oke-gpu-stack"
    "app.kubernetes.io/version"           = local.grafana_version
    version                               = local.grafana_version
    "service.istio.io/canonical-revision" = local.grafana_version
    "sidecar.istio.io/inject"             = "true"
  })
  grafana_helm_values = {
    remoteWriteDashboards = true
    grafana = {
      "grafana.ini" = {
        analytics = {
          enabled                  = false
          reporting_enabled        = false
          check_for_updates        = false
          check_for_plugin_updates = false
          feedback_links_enabled   = false
        }
        server = {
          enable_gzip = true
        }
        auth = {
          login_maximum_lifetime_duration = "120d"
          token_rotation_interval_minutes = 600
        }
        "auth.basic" = { enabled = true }
        users = {
          default_theme     = "light"
          viewers_can_edit  = true
          editors_can_admin = true
        }
      }
      replicas = 1
      podDisruptionBudget = {
        apiVersion     = "policy/v1"
        minAvailable   = 1
        maxUnavailable = 0
      }
      deploymentStrategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxSurge       = "100%"
          maxUnavailable = 0
        }
      }
      podPortName   = "http-web"
      podLabels     = local.grafana_labels
      adminUser     = "oke"
      adminPassword = "oke"
      inMemory      = { enabled = true }
      resources = {
        requests = {
          cpu    = "100m"
          memory = "4Gi"
        }
        limits = {
          cpu    = "8"
          memory = "8Gi"
        }
      }
      service = {
        enabled     = true
        type        = "ClusterIP"
        port        = 80
        targetPort  = 3000
        labels      = local.grafana_labels
        portName    = "http-web"
        appProtocol = "tcp"
      }
      extraVolumes = [
        {
          name = "fss", persistent_volume_claim = { claim_name = "oke-fss" }
        }
      ]
      extraVolumeMounts = [
        { name = "fss", mountPath = "/mnt/fss" }
      ]
    }
    sidecar = {
      dashboards = {
        enabled         = true
        label           = "grafana_dashboard"
        labelValue      = "1"
        searchNamespace = "ALL"
        provider        = { allowUiUpdates = true }
      }
    }
  }
}
