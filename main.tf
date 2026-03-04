terraform {
  required_providers {
    zillaforge = {
      source  = "hashicorp/zillaforge"
      version = "0.0.1-alpha"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "zillaforge" {
  api_endpoint     = var.api_endpoint
  api_key          = var.api_key
  project_sys_code = var.project_sys_code
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

data "zillaforge_images" "selected" {
  repository = var.image_repository != "" ? var.image_repository : null
  tag        = var.image_tag != "" ? var.image_tag : null
}

data "zillaforge_flavors" "selected" {
  name = var.flavor_name != "" ? var.flavor_name : null
}

data "zillaforge_networks" "selected" {
  name = var.network_name != "" ? var.network_name : null
}

data "zillaforge_security_groups" "selected" {
  name = var.sg_name != "" ? var.sg_name : null
}

data "zillaforge_keypairs" "selected" {
  name = var.keypair_name != "" ? var.keypair_name : null
}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  image_base_raw = data.zillaforge_images.selected.images[0].repository_name
  image_tag_raw  = data.zillaforge_images.selected.images[0].tag_name

  name_base = "${local.image_base_raw}-${local.image_tag_raw}"
}

# ---------------------------------------------------------------------------
# Floating IP
# ---------------------------------------------------------------------------

resource "zillaforge_floating_ip" "vm_fip" {
  count       = var.total
  name        = "${local.name_base}-fip-${count.index}"
  description = "Floating IP for Ubuntu 24.04 VM ${count.index}"
}

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

resource "zillaforge_server" "terraform_server" {
  count     = var.total
  name      = "${local.name_base}-vm-${count.index}"
  flavor_id = data.zillaforge_flavors.selected.flavors[0].id
  image_id  = data.zillaforge_images.selected.images[0].id
  keypair   = data.zillaforge_keypairs.selected.keypairs[0].id

  user_data = "apt update; apt install -y nginx"

  network_attachment {
    network_id         = data.zillaforge_networks.selected.networks[0].id
    primary            = true
    security_group_ids = [data.zillaforge_security_groups.selected.security_groups[0].id]
    floating_ip_id     = zillaforge_floating_ip.vm_fip[count.index].id
  }

  wait_for_active = true
}

resource "null_resource" "wait_for_all_vms" {
  triggers = {
    floating_ips = join(",", zillaforge_server.terraform_server[*].network_attachment[0].floating_ip)
  }

  provisioner "local-exec" {
    command = <<-EOT
      for ip in ${join(" ", zillaforge_server.terraform_server[*].network_attachment[0].floating_ip)}; do
        echo "Waiting for HTTP 200 from $ip ..."
        until [ "$(curl -s -o /dev/null -w '%%{http_code}' http://$ip)" = "200" ]; do
          echo "$ip not ready yet, retrying in 10 seconds..."
          sleep 10
        done
        echo "$ip is up and returned HTTP 200!"
      done
      echo "All VMs are ready!"
    EOT
  }

  depends_on = [zillaforge_server.terraform_server]
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "server_private_ips" {
  value = join(", ", flatten(zillaforge_server.terraform_server[*].ip_addresses))
}

output "server_floating_ips" {
  value = join(", ", zillaforge_server.terraform_server[*].network_attachment[0].floating_ip)
}

output "used_image" {
  description = "Image used by the servers (repository_name:tag_name)"
  value       = "${data.zillaforge_images.selected.images[0].repository_name}:${data.zillaforge_images.selected.images[0].tag_name}"
}

output "used_flavor" {
  description = "Flavor used by the servers (name, vCPUs, memory MB, disk GB)"
  value       = "${data.zillaforge_flavors.selected.flavors[0].name} (${data.zillaforge_flavors.selected.flavors[0].vcpus} vCPU, ${data.zillaforge_flavors.selected.flavors[0].memory} MB RAM, ${data.zillaforge_flavors.selected.flavors[0].disk} GB disk)"
}

output "used_network" {
  description = "Network attached to the servers"
  value       = "${data.zillaforge_networks.selected.networks[0].name} (${data.zillaforge_networks.selected.networks[0].cidr})"
}

output "used_security_group" {
  description = "Security group applied to the servers"
  value       = data.zillaforge_security_groups.selected.security_groups[0].name
}

output "used_keypair" {
  description = "SSH keypair injected into the servers"
  value       = data.zillaforge_keypairs.selected.keypairs[0].name
}