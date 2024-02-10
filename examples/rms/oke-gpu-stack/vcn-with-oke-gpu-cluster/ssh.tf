# Copyright (c) 2024 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

locals {
  ssh_public_key       = try(base64decode(var.ssh_public_key), var.ssh_public_key)
  ssh_public_key_path  = pathexpand(format("~/.ssh/oke.%s.pub", local.state_id))
  ssh_private_key_path = pathexpand(format("~/.ssh/oke.%s.pem", local.state_id))
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_pem" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = local.ssh_private_key_path
  file_permission = "0600"
}

resource "local_file" "ssh_pub" {
  content  = trimspace(tls_private_key.ssh.public_key_openssh)
  filename = local.ssh_public_key_path
}
