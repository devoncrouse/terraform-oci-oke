# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Identity
variable "tenancy_ocid" { type = string }
variable "compartment_ocid" { type = string }
variable "region" { type = string }
variable "current_user_ocid" {
  default = null
  type    = string
}
variable "api_fingerprint" {
  default = null
  type    = string
}
variable "oci_auth" {
  type        = string
  default     = null
  description = "One of [api_key instance_principal instance_principal_with_certs security_token resource_principal]"
}
variable "oci_profile" {
  type    = string
  default = null
}

# Cluster
variable "cluster_id" { type = string }
variable "gpu_namespace" { default = "gpu" }
variable "network_namespace" { default = "network" }
variable "monitoring_namespace" { default = "monitoring" }
variable "jupyter_namespace" { default = "jupyter" }
variable "inference_namespace" { default = "inference" }

# Storage
variable "mount_fss" { default = false }
variable "fss_ad" {
  default = null
  type    = string
}
variable "fss_mount_target_id" {
  default = null
  type    = string
}
variable "fss_namespaces" {
  default = ["default"]
  type    = list(string)
}

# Network
variable "vcn_id" {
  default = null
  type    = string
}
variable "vcn_compartment_ocid" {
  default = null
  type    = string
}
