# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# "oci.oraclecloud.com/host.id",
# "oci.oraclecloud.com/host.rack_id",
# "oci.oraclecloud.com/host.network_block_id",
# "oci.oraclecloud.com/fault-domain"
# "topology.kubernetes.io/zone",
# "topology.kubernetes.io/region",

locals {
  certManagerLabelSelector = {
    matchLabels = { "app.kubernetes.io/name" = "cert-manager" }
  }
  certManagerTopologySpreadConstraints = [
    {
      maxSkew           = 1
      labelSelector     = local.certManagerLabelSelector
      topologyKey       = "oci.oraclecloud.com/host.id"
      whenUnsatisfiable = "DoNotSchedule"
      #   whenUnsatisfiable = "ScheduleAnyway"
    },
  ]

  # certManagerAffinity = {
  #   podAntiAffinity = {
  #     requiredDuringSchedulingIgnoredDuringExecution = [
  #       {
  #         labelSelector = local.certManagerLabelSelector
  #         topologyKey   = "oci.oraclecloud.com/fault-domain"
  #       }
  #     ]
  #   }
  # }
}

resource "oci_containerengine_addon" "certmanager" {
  addon_name                       = "CertManager"
  cluster_id                       = module.oke.cluster_id
  remove_addon_resources_on_delete = false
  configurations {
    key   = "numOfReplicas"
    value = 2
  }
  configurations {
    key   = "nodeSelectors"
    value = "{\"oke.oraclecloud.com/pool.name\": \"oke-ops\"}"
  }
  # configurations {
  #   key   = "affinity"
  #   value = jsonencode(local.certManagerAffinity)
  # }
  configurations {
    key   = "topologySpreadConstraints"
    value = jsonencode(local.certManagerTopologySpreadConstraints)
  }
}
