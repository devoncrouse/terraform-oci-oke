# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  cluster_endpoints = module.oke.cluster_endpoints
  cluster_ca_cert   = module.oke.cluster_ca_cert
  cluster_id        = module.oke.cluster_id
  cluster_apiserver = try(trimspace(module.oke.apiserver_private_host), "")
}

module "oke" {
  source                       = "github.com/devoncrouse/terraform-oci-oke.git?ref=tf12&depth=1"
  providers                    = { oci.home = oci.home }
  region                       = var.region
  tenancy_id                   = var.tenancy_ocid
  compartment_id               = var.compartment_ocid
  state_id                     = local.state_id
  allow_bastion_cluster_access = true
  allow_node_port_access       = true
  allow_worker_internet_access = true
  allow_worker_ssh_access      = true
  assign_dns                   = var.assign_dns
  bastion_allowed_cidrs        = ["0.0.0.0/0"]
  bastion_await_cloudinit      = false
  bastion_is_public            = true
  bastion_shape = {
    shape = var.bastion_shape, ocpus = 4, memory = 16, boot_volume_size = 50
  }
  bastion_upgrade             = false
  cluster_name                = format("%v-%v", var.cluster_name, local.state_id)
  cluster_type                = "enhanced"
  cni_type                    = "flannel"
  control_plane_allowed_cidrs = ["0.0.0.0/0"]
  control_plane_is_public     = true
  create_bastion              = var.create_bastion
  create_cluster              = true
  create_iam_defined_tags     = false
  create_iam_resources        = false
  create_iam_tag_namespace    = false
  create_operator             = var.create_operator
  create_vcn                  = var.create_vcn
  kubernetes_version          = "v1.27.2"
  load_balancers              = "internal"
  lockdown_default_seclist    = true
  operator_await_cloudinit    = false
  operator_install_helm       = true
  operator_install_k9s        = true
  operator_install_kubectx    = true
  operator_shape = {
    shape            = var.operator_shape_name
    ocpus            = var.operator_shape_ocpus
    memory           = var.operator_shape_memory
    boot_volume_size = var.operator_shape_boot
  }
  output_detail                     = true
  pods_cidr                         = "10.248.0.0/16"
  preferred_load_balancer           = "internal"
  services_cidr                     = "10.98.0.0/16"
  ssh_public_key                    = trimspace(tls_private_key.ssh.public_key_openssh)
  use_defined_tags                  = false
  vcn_cidrs                         = split(",", var.vcn_cidrs)
  vcn_create_internet_gateway       = "always"
  vcn_create_nat_gateway            = "always"
  vcn_create_service_gateway        = "always"
  vcn_id                            = var.vcn_id
  vcn_name                          = var.vcn_name
  worker_cloud_init                 = local.worker_cloud_init
  worker_disable_default_cloud_init = true
  worker_is_public                  = false
  worker_pools                      = local.worker_pools
  subnets = {
    bastion  = { create = "always", newbits = 13 }
    cp       = { create = "always", newbits = 13 }
    operator = { create = "always", newbits = 13 }
    int_lb   = { create = "always", newbits = 11 }
    pub_lb   = { create = "always", newbits = 11 }
    fss      = { create = "always", newbits = 11 }
    workers  = { create = "always", newbits = 4 }
  }
  nsgs = {
    bastion  = { create = "always" }
    cp       = { create = "always" }
    operator = { create = "always" }
    int_lb   = { create = "always" }
    pub_lb   = { create = "always" }
    fss      = { create = "always" }
    workers  = { create = "always" }
  }
  allow_rules_internal_lb = {
    "Allow TCP ingress to internal load balancers from internal VCN/DRG" = {
      protocol = "all", port = -1, source = "10.0.0.0/8", source_type = "CIDR_BLOCK",
    }
  }
}
