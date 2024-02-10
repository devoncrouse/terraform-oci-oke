# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  imds_instance_url = "http://169.254.169.254/opc/v2/instance"
  imds_curl_args    = "-s -H 'Authorization: Bearer Oracle'"
  imds_pool         = join("/", [local.imds_instance_url, "freeformTags/pool"])
  imds_region       = join("/", [local.imds_instance_url, "regionInfo/regionKey"])
  imds_instance     = join("/", [local.imds_instance_url, "displayName"])
  imds_ad           = join("/", [local.imds_instance_url, "ociAdName"])
  imds_fd           = join("/", [local.imds_instance_url, "faultDomain"])

  path_labels = "/run/prometheus/static"

  node_exporter_helm = {
    enabled = true
    operatingSystems = {
      linux  = { enabled = true }
      darwin = { enabled = false }
    }
  }

  node_exporter_extra_args = [
    "--collector.cgroups",
    "--collector.ethtool",
    "--collector.mountstats",
    "--collector.qdisc",
    "--collector.processes",
    "--collector.sysctl",
    "--collector.sysctl.include=^net.ipv4.conf.(.+).(arp_ignore|arp_announce|rp_filter)$",
    format("--collector.textfile.directory=%v", local.path_labels),
    "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)",
    "--collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
  ]

  label_volume = { name = "shm", emptyDir = { medium = "Memory" } }

  labels = [for c in [
    { source = local.imds_pool, path = join("/", [local.path_labels, "pool.prom"]) },
    { source = local.imds_region, path = join("/", [local.path_labels, "region.prom"]) },
    { source = local.imds_instance, path = join("/", [local.path_labels, "instance.prom"]) },
    { source = local.imds_ad, path = join("/", [local.path_labels, "ad.prom"]) },
    { source = local.imds_fd, path = join("/", [local.path_labels, "fd.prom"]) },
  ] : format("curl %s %s | tee %s", local.imds_curl_args, c.source, c.path)]

  label_command = [
    "bash", "-c", format("mkdir -vp %v\n%v", local.path_labels, join("\n", local.labels))
  ]

  node_exporter_values = {
    releaseLabel = true
    sidecarVolumeMount = [
      { name = "static", mountPath = local.path_labels, readOnly = false },
    ]
    extraInitContainers = [
      {
        command = local.label_command
        image   = "oraclelinux:9"
        name    = "instance-metadata-labels"
        volumeMounts = [{ mountPath = local.path_labels, name = "static" }]
      }
    ]
    prometheus = {
      monitor = {
        attachMetadata   = { node = true }
        selectorOverride = {}
        interval         = "10s"
        scrapeTimeout    = "10s"
        relabelings = [
          {
            sourceLabels = ["__meta_kubernetes_node_label_oke_oraclecloud_com_tf_state_id"]
            targetLabel  = "tf_state_id"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_oke_oraclecloud_com_pool_name"]
            targetLabel  = "worker_pool"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_topology_kubernetes_io_region"]
            targetLabel  = "region"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_topology_kubernetes_io_zone"]
            targetLabel  = "zone"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_oci_oraclecloud_com_fault_domain"]
            targetLabel  = "fault_domain"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_node_kubernetes_io_instance_type"]
            targetLabel  = "instance_shape"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_oci_oraclecloud_com_host_serial_number"]
            targetLabel  = "host_serial_number"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_oci_oraclecloud_com_host_rack_id"]
            targetLabel  = "host_rack_id"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_label_oci_oraclecloud_com_host_id"]
            targetLabel  = "host_id"
          }
        ]
      }
    }
    extraArgs = local.node_exporter_extra_args
  }
}
