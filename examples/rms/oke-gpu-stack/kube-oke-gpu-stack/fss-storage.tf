# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  fss_enabled         = var.mount_fss && var.fss_mount_target_id != null
  fss_volume_name     = "oke-fss"
  fss_mount_target    = one(one(data.oci_file_storage_mount_targets.fss[*].mount_targets))
  fss_mount_target_id = try(lookup(local.fss_mount_target, "id", null), null)
  fss_private_ip_id   = try(one(lookup(local.fss_mount_target, "private_ip_ids", [])), null)
  fss_export_set_id   = try(lookup(local.fss_mount_target, "export_set_id", null), null)
  fss_ip_address      = one(data.oci_core_private_ip.fss[*].ip_address)
  fss_export          = one(data.oci_file_storage_exports.fss[*].exports)
  fss_file_system_id  = try(lookup(local.fss_export, "file_system_id", null), null)
  fss_volume_handle   = format("%v:%v:%s", local.fss_file_system_id, local.fss_ip_address, "/")
  fss_size            = "2Ti" # TODO
  fss_namespaces      = ["default"]
}

data "oci_file_storage_mount_targets" "fss" {
  count               = local.fss_enabled ? 1 : 0
  availability_domain = var.fss_ad
  compartment_id      = var.compartment_ocid
  id                  = var.fss_mount_target_id
}

data "oci_file_storage_exports" "fss" {
  count          = local.fss_enabled ? 1 : 0
  compartment_id = var.compartment_ocid
  export_set_id  = local.fss_export_set_id
}

data "oci_core_private_ip" "fss" {
  count         = local.fss_enabled ? 1 : 0
  private_ip_id = local.fss_private_ip_id
}

resource "kubernetes_storage_class_v1" "fss" {
  count = local.fss_enabled ? 1 : 0
  metadata { name = "fss" }
  storage_provisioner = "fss.csi.oraclecloud.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    mountTargetOcid    = var.fss_mount_target_id
    exportPath         = "/"
    encryptInTransit   = "false"
    compartmentOcid    = var.compartment_ocid
    availabilityDomain = var.fss_ad
  }
}

resource "kubernetes_persistent_volume_v1" "fss" {
  for_each   = local.fss_enabled ? { for ns in local.fss_namespaces : ns => {} } : {}
  depends_on = [kubernetes_storage_class_v1.fss]
  metadata {
    name = format("%v-%v", local.fss_volume_name, each.key)
  }
  spec {
    capacity                         = { storage = local.fss_size }
    storage_class_name               = "none"
    volume_mode                      = "Filesystem"
    access_modes                     = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      csi {
        driver            = "fss.csi.oraclecloud.com"
        volume_attributes = { encrypt_in_transit = false }
        volume_handle     = local.fss_volume_handle
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "fss" {
  for_each = local.fss_enabled ? { for ns in local.fss_namespaces : ns => {} } : {}
  depends_on = [
    kubernetes_storage_class_v1.fss,
    kubernetes_persistent_volume_v1.fss,
  ]
  metadata {
    name      = local.fss_volume_name
    namespace = each.key
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    volume_name        = format("%v-%v", local.fss_volume_name, each.key)
    storage_class_name = "none"
    resources {
      requests = { storage = local.fss_size }
    }
  }
}
