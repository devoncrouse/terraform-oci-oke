# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Terraform
output "state_id" { value = module.oke.state_id }

# Identity
output "dynamic_group_ids" { value = module.oke.dynamic_group_ids }
output "policy_statements" { value = module.oke.policy_statements }

# Network
output "vcn_id" { value = module.oke.vcn_id }
output "bastion_public_ip" { value = module.oke.bastion_public_ip }
output "bastion_ssh_command" { value = module.oke.ssh_to_bastion }
output "bastion_nsg_id" { value = module.oke.bastion_nsg_id }

# Cluster
output "cluster_id" { value = module.oke.cluster_id }
output "cluster_endpoints" { value = module.oke.cluster_endpoints }
output "cluster_kubeconfig" { value = module.oke.cluster_kubeconfig }
output "cluster_ca_cert" { value = module.oke.cluster_ca_cert }
output "control_plane_subnet_id" { value = module.oke.control_plane_subnet_id }
output "control_plane_nsg_id" { value = module.oke.control_plane_nsg_id }
output "int_lb_subnet_id" { value = module.oke.int_lb_subnet_id }
output "pub_lb_subnet_id" { value = module.oke.pub_lb_subnet_id }

# Storage
output "fss_volume_name" { value = local.fss_volume_name }
output "fss_nsg_id" { value = local.fss_nsg_id }
output "fss_subnet_id" { value = local.fss_subnet_id }
output "fss_mount_target_ip" { value = local.fss_ip_address }

# Operator
output "operator_id" { value = module.oke.operator_id }
output "operator_private_ip" { value = module.oke.operator_private_ip }
output "operator_ssh_command" { value = module.oke.ssh_to_operator }
output "operator_subnet_id" { value = module.oke.operator_subnet_id }
output "operator_nsg_id" { value = module.oke.operator_nsg_id }
