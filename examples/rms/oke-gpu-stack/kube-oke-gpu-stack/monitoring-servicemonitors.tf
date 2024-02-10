# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "kubernetes_manifest" "service_monitor_gpu_operator" {
  count      = 0
  depends_on = [kubernetes_namespace_v1.monitoring]
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "gpu-operator"
      namespace = var.monitoring_namespace
      labels    = local.monitoring_labels
    }
    spec = {
      endpoints = [{
        path = "/metrics"
        port = "gpu-operator-metrics"
      }]
      jobLabel = "operator"
      namespaceSelector = {
        matchNames = ["gpu", "gpu-operator"]
      }
      selector = {
        matchLabels = { app = "gpu-operator" }
      }
    }
  }
}
