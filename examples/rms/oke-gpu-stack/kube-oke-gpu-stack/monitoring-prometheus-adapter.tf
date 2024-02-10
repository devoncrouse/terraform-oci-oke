# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  install_prometheus_adapter = true
  prometheus_adapter_helm_values = {
    podDisruptionBudget = { enabled = true }
    replicas            = 2
    prometheus = {
      url  = "http://prometheus-kube-prometheus-prometheus.monitoring.svc"
      port = 9090
      path = ""
    }
    rules = {
      default = true
      custom  = []
      external = []

      resource = {
        cpu = {
          containerLabel = "container"
          containerQuery = "sum by (<<.GroupBy>>) (rate(container_cpu_usage_seconds_total{container!=\"\",<<.LabelMatchers>>}[3m]))"
          nodeQuery      = "sum  by (<<.GroupBy>>) (rate(node_cpu_seconds_total{mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\",<<.LabelMatchers>>}[3m]))"
          resources = {
            overrides = {
              node      = { resource = "node" }
              namespace = { resource = "namespace" }
              pod       = { resource = "pod" }
            }
          }
        }
        memory = {
          containerQuery = "sum by (<<.GroupBy>>) (avg_over_time(container_memory_working_set_bytes{container!=\"\",<<.LabelMatchers>>}[3m]))"
          nodeQuery      = <<-EOT
            sum by (<<.GroupBy>>) (
              avg_over_time(node_memory_MemTotal_bytes{<<.LabelMatchers>>}[3m])
              -
              avg_over_time(node_memory_MemAvailable_bytes{<<.LabelMatchers>>}[3m])
            )
          EOT
          resources = {
            overrides = {
              node      = { resource = "node" }
              namespace = { resource = "namespace" }
              pod       = { resource = "pod" }
            }
          }
          containerLabel = "container"
        }
        window = "3m"
      }
    }
  }

  prometheus_adapter_helm_values_yaml = jsonencode(local.prometheus_adapter_helm_values)
}

resource "helm_release" "prometheus_adapter" {
  depends_on       = [kubernetes_namespace_v1.monitoring, helm_release.prometheus]
  count            = local.install_prometheus_adapter ? 1 : 0
  namespace        = var.monitoring_namespace
  name             = "prometheus-adapter"
  chart            = "prometheus-adapter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  version          = "4.9.0"
  create_namespace = false
  recreate_pods    = true
  force_update     = true
  max_history      = 1
  values           = [local.prometheus_adapter_helm_values_yaml]
}
