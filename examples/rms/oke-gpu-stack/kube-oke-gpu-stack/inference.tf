# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "kubernetes_namespace_v1" "inference" {
  metadata {
    name = var.inference_namespace
    labels = {
      istio-injection               = "enabled"
      "kubernetes.io/metadata.name" = var.inference_namespace
      "kiali.io/member-of"          = "istio-system"
    }
  }
}
