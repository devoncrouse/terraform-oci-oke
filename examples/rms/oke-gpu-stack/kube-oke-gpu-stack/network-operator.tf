# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  network_operator_name = "network-operator"
  network_operator_helm_values = {
    deployCR = true
    nfd = {
      enabled                = false # enabled on gpu-operator
      deployNodeFeatureRules = false
    }
    rdmaSharedDevicePlugin = { deploy = false }
    nvIpam                 = { deploy = true }
    secondaryNetwork = {
      deploy     = true
      ipamPlugin = { deploy = false }
    }
    nicFeatureDiscovery = { deploy = true }
    nvPeerDriver        = { deploy = true }
    sriovDevicePlugin = { deploy = true, useCdi = true, resources = [
      { name = "sriov_rdma_vf", vendors = ["15b3"], devices = ["101a", "101e"], isRdma = true }
    ] }
  }

  network_operator_helm_values_yaml = jsonencode(local.network_operator_helm_values)
}

resource "kubernetes_namespace_v1" "network" {
  metadata {
    name = var.network_namespace
    labels = {
      "istio-injection"             = "disabled"
      "kubernetes.io/metadata.name" = var.network_namespace
      "kiali.io/member-of"          = "istio-system"
    }
  }
}

resource "helm_release" "network_operator" {
  depends_on       = [kubernetes_namespace_v1.network]
  chart            = "https://helm.ngc.nvidia.com/nvidia/charts/network-operator-23.10.0.tgz"
  name             = local.network_operator_name
  namespace        = var.network_namespace
  values           = [local.network_operator_helm_values_yaml]
  create_namespace = false
  force_update     = true
  recreate_pods    = true
  max_history      = 1
}
