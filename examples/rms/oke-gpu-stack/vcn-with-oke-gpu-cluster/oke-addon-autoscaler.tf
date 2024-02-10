# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler
# https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengautoscalingclusters.htm

locals {
  # Active worker pools that should be managed by the cluster autoscaler
  worker_pools_ops = lookup(coalesce(module.oke.worker_pool_ids, {}), "oke-ops", null)
  worker_pools_gpu = lookup(coalesce(module.oke.worker_pool_ids, {}), "oke-gpu", null)
}

resource "oci_containerengine_addon" "cluster_autoscaler" {
  addon_name                       = "ClusterAutoscaler"
  cluster_id                       = module.oke.cluster_id
  remove_addon_resources_on_delete = true
  configurations {
    key   = "authType"
    value = "instance"
  }
  configurations {
    key   = "numOfReplicas"
    value = "1"
  }
  configurations {
    key   = "enforceNodeGroupMinSize"
    value = "true"
  }
  configurations {
    key   = "nodeSelectors"
    value = "{ \"oke.oraclecloud.com/pool.name\":\"oke-ops\" }"
  }
  configurations {
    key = "nodes"
    value = join(", ", compact([
      local.worker_pools_ops != null ? format("1:3:%s", local.worker_pools_ops) : null,
      local.worker_pools_gpu != null ? format("0:3:%s", local.worker_pools_gpu) : null
    ]))
  }
  configurations {
    key   = "maxNodeProvisionTime"
    value = "15m"
  }
  configurations {
    key   = "scaleDownDelayAfterAdd"
    value = "15m"
  }
  configurations {
    key   = "scaleDownUnneededTime"
    value = "4h"
  }
  configurations {
    key   = "annotations"
    value = "{\"prometheus.io/scrape\":\"true\",\"prometheus.io/port\":\"8086\"}"
  }
}
