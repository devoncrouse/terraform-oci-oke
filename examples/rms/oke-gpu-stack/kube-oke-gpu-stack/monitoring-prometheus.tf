# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  prometheus_version = "2.48"
  prometheus_labels = merge(local.monitoring_labels, {
    app                                   = "prometheus"
    "app.kubernetes.io/name"              = "prometheus"
    "service.istio.io/canonical-name"     = "prometheus"
    "app.kubernetes.io/part-of"           = "oke-gpu-stack"
    "app.kubernetes.io/version"           = local.prometheus_version
    version                               = local.prometheus_version
    "service.istio.io/canonical-revision" = local.prometheus_version
    "sidecar.istio.io/inject"             = "true"
  })

  admission_labels = merge(local.prometheus_labels, {
    app                               = "prometheus-admission"
    "app.kubernetes.io/name"          = "prometheus-admission"
    "service.istio.io/canonical-name" = "prometheus-admission"
    "sidecar.istio.io/inject"         = "false"
  })

  prometheus_helm_values = merge({
    alertmanager = { enabled = false }
    defaultRules = { create = false }
    prometheusOperator = {
      admissionWebhooks = {
        enabled    = true
        deployment = { enabled = true }
      }
    }
    prometheus = {
      service = {
        annotations = {}
        labels      = local.prometheus_labels
        clusterIP   = ""
      }
      prometheusSpec = {
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        ruleSelectorNilUsesHelmValues           = false
        probeSelectorNilUsesHelmValues          = false
        scrapeConfigSelectorNilUsesHelmValues   = false
        scrapeInterval                          = "10s"
        scrapeTimeout                           = "10s"
        retention                               = "7d"
        requests = {
          cpu    = "1000m"
          memory = "8Gi"
        }
        limits = {
          memory = "16Gi"
        }
      }
      storageSpec = {
        volumeClaimTemplate = {
          selector = {}
          spec = {
            storageClassName = "oci-bv"
            accessModes      = ["ReadWriteOnce"]
            resources = {
              requests = { storage = "100Gi" }
            }
          }
        }
      }
    }
    nodeExporter             = local.node_exporter_helm
    prometheus-node-exporter = local.node_exporter_values
  }, local.grafana_helm_values)
  prometheus_helm_values_yaml = jsonencode(local.prometheus_helm_values)
}

resource "helm_release" "prometheus" {
  depends_on        = [kubernetes_namespace_v1.monitoring]
  namespace         = var.monitoring_namespace
  name              = "prometheus"
  chart             = "kube-prometheus-stack"
  repository        = "https://prometheus-community.github.io/helm-charts"
  version           = "55.5.0"
  values            = [local.prometheus_helm_values_yaml]
  create_namespace  = false
  recreate_pods     = true
  force_update      = true
  dependency_update = true
  wait              = false
  max_history       = 1
}
