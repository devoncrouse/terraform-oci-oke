# Copyright (c) 2023 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  worker_image_id   = coalesce(var.worker_image_custom_id, var.worker_image_platform_id, "none")
  worker_image_type = contains(["platform", "custom"], lower(var.worker_image_type)) ? "custom" : "oke"

  worker_cloud_init = var.worker_cloud_init_configure ? [{
    content_type = var.worker_cloud_init_content_type,
    content      = var.worker_cloud_init
  }] : []
}

module "oke" {
  source    = "github.com/oracle-terraform-modules/terraform-oci-oke.git?ref=tf12&depth=1"
  providers = { oci.home = oci.home }

  # Identity
  tenancy_id     = var.tenancy_ocid
  compartment_id = var.compartment_ocid

  create_iam_resources         = true
  create_iam_autoscaler_policy = var.create_iam_autoscaler_policy ? "always" : "never"
  create_iam_worker_policy     = var.create_iam_worker_policy ? "always" : "never"
  create_bastion               = false
  create_operator              = false
  create_cluster               = false

  # Network
  create_vcn     = false
  vcn_id         = var.vcn_id
  assign_dns     = var.assign_dns
  worker_nsg_ids = compact([var.worker_nsg_id])
  pod_nsg_ids    = compact([var.pod_nsg_id])

  subnets = {
    workers = { create = "never", id = var.worker_subnet_id }
    pods    = { create = "never", id = var.pod_subnet_id }
  }

  nsgs = {
    workers = { create = "never", id = var.worker_nsg_id }
    pods    = { create = "never", id = var.pod_nsg_id }
  }

  # Cluster
  cluster_id              = var.cluster_id
  cni_type                = lower(var.cni_type)
  control_plane_is_public = false # workers only need private
  kubernetes_version      = "v1.27.2"


  # Workers
  ssh_public_key   = local.ssh_public_key
  worker_pool_size = var.worker_pool_size
  worker_pool_mode = lookup({
    "Node Pool"         = "node-pool"
    "Virtual Node Pool" = "virtual-node-pool"
    "Instance"          = "instance"
    "Instance Pool"     = "instance-pool",
    "Cluster Network"   = "cluster-network",
  }, var.worker_pool_mode, "node-pool")

  worker_image_type                 = lower(local.worker_image_type)
  worker_image_id                   = local.worker_image_id
  worker_image_os                   = var.worker_image_os
  worker_image_os_version           = var.worker_image_os_version
  worker_cloud_init                 = local.worker_cloud_init
  worker_disable_default_cloud_init = var.worker_disable_default_cloud_init

  worker_shape = {
    shape = (var.worker_pool_mode == "Virtual Node Pool"
      ? var.virtual_worker_shape : var.worker_shape
    )
    ocpus            = var.worker_ocpus
    memory           = var.worker_memory
    boot_volume_size = var.worker_boot_volume_size
  }

  worker_pools = {
    format("%v", var.worker_pool_name) = {
      description = lookup({
        "Node Pool"         = "OKE-managed Node Pool"
        "Virtual Node Pool" = "OKE-managed Virtual Node Pool"
        "Instance"          = "Self-managed Instances"
        "Instance Pool"     = "Self-managed Instance Pool"
        "Cluster Network"   = "Self-managed Cluster Network"
      }, var.worker_pool_mode, "")
    }
  }

  agent_config = {
    are_all_plugins_disabled = var.agent_are_all_plugins_disabled
    is_management_disabled   = var.agent_is_management_disabled
    is_monitoring_disabled   = var.agent_is_monitoring_disabled
    plugins_config = {
      "Bastion"                             = var.agent_plugin_bastion ? "ENABLED" : "DISABLED"
      "Block Volume Management"             = var.agent_plugin_block_volume_management ? "ENABLED" : "DISABLED"
      "Compute HPC RDMA Authentication"     = var.agent_plugin_compute_hpc_rdma_authentication ? "ENABLED" : "DISABLED"
      "Compute HPC RDMA Auto-Configuration" = var.agent_plugin_compute_hpc_rdma_auto_configuration ? "ENABLED" : "DISABLED"
      "Compute Instance Monitoring"         = var.agent_plugin_compute_instance_monitoring ? "ENABLED" : "DISABLED"
      "Compute Instance Run Command"        = var.agent_plugin_compute_instance_run_command ? "ENABLED" : "DISABLED"
      "Compute RDMA GPU Monitoring"         = var.agent_plugin_compute_rdma_gpu_monitoring ? "ENABLED" : "DISABLED"
      "Custom Logs Monitoring"              = var.agent_plugin_custom_logs_monitoring ? "ENABLED" : "DISABLED"
      "Management Agent"                    = var.agent_plugin_management_agent ? "ENABLED" : "DISABLED"
      "Oracle Autonomous Linux"             = var.agent_plugin_oracle_autonomous_linux ? "ENABLED" : "DISABLED"
      "OS Management Service Agent"         = var.agent_plugin_os_management_service_agent ? "ENABLED" : "DISABLED"
    }
  }

  freeform_tags = {
    workers = lookup(var.worker_tags, "freeformTags", {
      created = format("%d", time_static.created.unix),
    })
  }

  defined_tags = {
    workers = lookup(var.worker_tags, "definedTags", {})
  }
}

resource "time_static" "created" {}
