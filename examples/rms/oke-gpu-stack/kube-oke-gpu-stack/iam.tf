# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  state_id = random_string.state_id.id
}

data "oci_identity_availability_domains" "all" {
  compartment_id = var.compartment_ocid
}

resource "random_string" "state_id" {
  length  = 6
  lower   = true
  numeric = false
  special = false
  upper   = false
}
