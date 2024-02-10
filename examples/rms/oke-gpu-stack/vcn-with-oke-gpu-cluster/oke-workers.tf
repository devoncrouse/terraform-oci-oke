# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  create_workers = true
  ssh_authorized_keys = [
    trimspace(local.ssh_public_key),
    trimspace(tls_private_key.ssh.public_key_openssh)
  ]

  fs_setup = [
    { device = "/dev/nvme0n1", filesystem = "ext4", label = "nvme0n1" }
  ]
  disk_setup = {
    "/dev/nvme0n1" = { layout = true, overwrite = true, table_type = "gpt" }
  }
  mounts = [
    ["/dev/nvme0n1", "/mnt/local/nvme0"]
  ]

  #repo_uri = "https://objectstorage.ap-osaka-1.oraclecloud.com/p/LtN5W_61bXynNHZ4J9G2dRkDiC3MWPn7vQcE4GznMJwqqZDqjAmehHuogYUld5ht/n/hpc_limited_availability/b/oke_node_repo"
  image_id = "ocid1.image.oc1.us-chicago-1.aaaaaaaa3zu67rkg6gpiwnvald2kn7eudikgv5ixkz3onild2jbq5tdw4yxq"
  repo_uri = "https://objectstorage.us-chicago-1.oraclecloud.com/p/54DVYQqXO2vG5vvhPDxOiH092Z8DyJkrc_ShJI4JzmPhjbUcqK2YRsweByiFfsDd/n/hpc_limited_availability/b/oke_node_repo"
  yum_repos = {
    oke-node = {
      name     = "Oracle Container Engine for Kubernetes Nodes"
      baseurl  = "${local.repo_uri}/o/el/$releasever/$basearch"
      gpgcheck = false
    }
  }
  apt = {
    sources = {
      oke-node = {
        source = "deb [trusted=yes] ${local.repo_uri}/o/ubuntu stable main"
      }
    }
  }
  packages = [
    ["oci-oke-node-all", "1.27.2*"]
  ]

  runcmd_bootstrap_nogpudp = <<-EOT
    oke bootstrap \
        --label oci.oraclecloud.com/disable-gpu-device-plugin=true \
        --crio-extra-args "--root /var/lib/oke-crio/root --runroot /var/lib/oke-crio/state" \
      || echo Failed >&2
  EOT

  write_files = [
    {
      content = local.cluster_apiserver,
      path    = "/etc/oke/oke-apiserver",
    },
    {
      encoding    = "b64",
      content     = local.cluster_ca_cert,
      owner       = "root:root",
      path        = "/etc/kubernetes/ca.crt",
      permissions = "0644",
    }
  ]
  cloud_init = {
    ssh_authorized_keys = local.ssh_authorized_keys
    yum_repos           = local.yum_repos
    apt                 = local.apt
    packages            = local.packages
    runcmd              = [local.runcmd_bootstrap_nogpudp]
    write_files         = local.write_files
  }

  worker_cloud_init = [{ content_type = "text/cloud-config", content = yamlencode(local.cloud_init) }]
  worker_pools = {
    "oke-ops" = {
      create           = local.create_workers
      description      = "OKE-managed VM Node Pool for cluster operations and monitoring"
      size             = var.worker_ops_pool_size
      shape            = var.worker_ops_shape
      ocpus            = var.worker_ops_ocpus
      memory           = var.worker_ops_memory
      boot_volume_size = 128
    }
    "oke-cpu" = {
      create           = local.create_workers && var.worker_cpu_enabled
      description      = "OKE-managed CPU Node Pool"
      size             = var.worker_cpu_pool_size
      shape            = var.worker_cpu_shape
      ocpus            = var.worker_cpu_ocpus
      memory           = var.worker_cpu_memory
      boot_volume_size = var.worker_cpu_boot_volume_size
      image_id         = local.image_id
    }
    "oke-gpu" = {
      create           = local.create_workers && var.worker_gpu_enabled
      description      = "OKE-managed GPU Node Pool"
      size             = var.worker_gpu_pool_size
      shape            = var.worker_gpu_shape
      boot_volume_size = var.worker_gpu_boot_volume_size
      image_type       = "custom"
      image_id         = local.image_id
    }
    "oke-rdma" = {
      create           = local.create_workers && var.worker_rdma_enabled
      description      = "Self-managed Cluster Network with RDMA"
      placement_ads    = [1]
      mode             = "cluster-network"
      size             = var.worker_rdma_pool_size
      shape            = var.worker_rdma_shape
      boot_volume_size = var.worker_rdma_boot_volume_size
      image_type       = "custom"
      image_id         = local.image_id
      agent_config = {
        are_all_plugins_disabled = false
        is_management_disabled   = false
        is_monitoring_disabled   = false
        plugins_config = {
          "Bastion"                             = "DISABLED"
          "Block Volume Management"             = "DISABLED"
          "Compute HPC RDMA Authentication"     = "ENABLED"
          "Compute HPC RDMA Auto-Configuration" = "ENABLED"
          "Compute Instance Monitoring"         = "ENABLED"
          "Compute Instance Run Command"        = "ENABLED"
          "Compute RDMA GPU Monitoring"         = "ENABLED"
          "Custom Logs Monitoring"              = "ENABLED"
          "Management Agent"                    = "ENABLED"
          "Oracle Autonomous Linux"             = "DISABLED"
          "OS Management Service Agent"         = "DISABLED"
        }
      }
    }
  }
}
