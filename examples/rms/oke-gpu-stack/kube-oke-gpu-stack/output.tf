# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "state_id" { value = local.state_id }
output "cluster_endpoint" { value = local.cluster_endpoint }
output "cluster_id" { value = var.cluster_id }
output "kubeconfig" { value = yamlencode(local.kubeconfig) }
output "service_account_secret_name" { value = local.user_name }

output "fss_availability_domain" { value = var.fss_ad }
output "fss_file_system_id" { value = local.fss_file_system_id }
output "fss_mount_target_id" { value = local.fss_mount_target_id }
output "fss_export_set_id" { value = local.fss_export_set_id }
output "fss_private_ip_id" { value = local.fss_private_ip_id }
output "fss_ip_address" { value = local.fss_ip_address }
