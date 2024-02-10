# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "assign_dns" { default = true }
variable "compartment_ocid" { type = string }
variable "cluster_name" { default = "oke-gpu-quickstart" }
variable "control_plane_allowed_cidrs" { default = "10.123.0.0/16" }
variable "create_policies" { default = true }
variable "create_vcn" { default = true }
variable "kubernetes_version" { default = "v1.27.2" }
variable "region" { type = string }
variable "tenancy_ocid" { type = string }
variable "vcn_cidrs" { default = "10.123.0.0/16" }
variable "vcn_name" { default = "oke-gpu-quickstart" }
variable "bastion_shape" { default = "VM.Standard.E4.Flex" }
variable "create_bastion" { default = true }

variable "create_operator" { default = false }
variable "operator_shape_config" { default = false }
variable "operator_shape_name" { default = "VM.Standard.E4.Flex" }
variable "operator_shape_ocpus" { default = 2 }
variable "operator_shape_memory" { default = 2 }
variable "operator_shape_boot" { default = 50 }

variable "create_fss" { default = true }
variable "fss_ad" { default = "" }
variable "fss_size" { default = 2000 }

variable "worker_ops_memory" { default = 64 }
variable "worker_ops_ocpus" { default = 16 }
variable "worker_ops_pool_size" { default = 3 }
variable "worker_ops_shape" { default = "VM.Standard.E4.Flex" }

variable "worker_cpu_boot_volume_size" { default = 512 }
variable "worker_cpu_enabled" { default = false }
variable "worker_cpu_image_id" { default = null }
variable "worker_cpu_image_os_version" { default = "8" }
variable "worker_cpu_image_os" { default = "Oracle Linux" }
variable "worker_cpu_image_type" { default = "OKE" }
variable "worker_cpu_memory" { default = 32 }
variable "worker_cpu_ocpus" { default = 5 }
variable "worker_cpu_pool_size" { default = 1 }
variable "worker_cpu_shape" { default = "BM.Standard3.64" }

variable "worker_gpu_boot_volume_size" { default = 512 }
variable "worker_gpu_enabled" { default = false }
variable "worker_gpu_pool_size" { default = 1 }
variable "worker_gpu_shape" { default = "VM.GPU3.1" }

variable "worker_rdma_boot_volume_size" { default = 512 }
variable "worker_rdma_enabled" { default = false }
variable "worker_rdma_pool_size" { default = 4 }
variable "worker_rdma_shape" { default = "BM.GPU.H100.8" }

variable "worker_cpu_image_platform_id" {
  default = null
  type    = string
}
variable "worker_cpu_image_custom_id" {
  default = null
  type    = string
}
variable "current_user_ocid" {
  default = null
  type    = string
}
variable "api_fingerprint" {
  default = null
  type    = string
}
variable "ssh_public_key" {
  default = null
  type    = string
}
variable "vcn_id" {
  default = null
  type    = string
}
variable "vcn_compartment_ocid" {
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
