# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  monitoring_version = "1"
  monitoring_labels = {
    app                         = var.monitoring_namespace
    "app.kubernetes.io/name"    = var.monitoring_namespace
    "app.kubernetes.io/part-of" = "oke-gpu-stack"
    "app.kubernetes.io/version" = local.monitoring_version
    version                     = local.monitoring_version
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.monitoring_namespace
    labels = {
      "istio-injection"             = "enabled"
      "kubernetes.io/metadata.name" = "monitoring"
      "kiali.io/member-of"          = "istio-system"
    }
  }
}
