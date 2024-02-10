# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  kube_system_namespace = "kube-system"
  kubeconfig            = yamldecode(data.oci_containerengine_cluster_kube_config.oke.content)
  kubeconfig_cluster    = try(lookup(lookup(local.kubeconfig, "clusters", [{}])[0], "cluster", {}), {})
  cluster_ca_cert       = lookup(local.kubeconfig_cluster, "certificate-authority-data", "")
  user_name             = format("oke-%s-svcacct", local.state_id)
  user_token = {
    name = local.user_name, user = {
      "token" = try(one(kubernetes_token_request_v1.admin[*].token), "missing")
    }
  }
  cluster_id_safe  = coalesce(var.cluster_id, "unknown")
  cluster_endpoint = lookup(local.kubeconfig_cluster, "server", "")
  cluster_short    = substr(local.cluster_id_safe, length(local.cluster_id_safe) - 11, 11)
  cluster_name     = format("cluster-%s", local.cluster_short)
  cluster_field = {
    server = local.cluster_endpoint
    "certificate-authority-data" : local.cluster_ca_cert
  }
  cluster = { name = local.cluster_name, cluster = local.cluster_field }
  user_token_args = concat(
    ["--region", var.region],
    var.oci_profile != null ? ["--profile", var.oci_profile] : [],
    ["ce", "cluster", "generate-token"],
    ["--cluster-id", var.cluster_id],
  )
}

data "oci_containerengine_cluster_kube_config" "oke" {
  cluster_id = var.cluster_id
  endpoint   = "PUBLIC_ENDPOINT"
}

resource "kubernetes_service_account_v1" "admin" {
  metadata {
    name      = local.user_name
    namespace = local.kube_system_namespace
  }
  secret { name = local.user_name }
  image_pull_secret { name = local.user_name }
}

resource "kubernetes_secret_v1" "service_account_admin" {
  depends_on = [kubernetes_service_account_v1.admin]
  type       = "kubernetes.io/service-account-token"
  metadata {
    name        = local.user_name
    namespace   = local.kube_system_namespace
    annotations = { "kubernetes.io/service-account.name" = local.user_name }
  }
}

resource "kubernetes_token_request_v1" "admin" {
  depends_on = [kubernetes_service_account_v1.admin]
  metadata {
    name      = local.user_name
    namespace = local.kube_system_namespace
  }
  spec {
    expiration_seconds = 20 * 31557600 # 20 years
    audiences          = ["api", "vault", "factors"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "admin" {
  depends_on = [kubernetes_service_account_v1.admin]
  metadata {
    name = local.user_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.user_name
    namespace = local.kube_system_namespace
  }
}
