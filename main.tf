terraform {
  required_providers {
    zillaforge = {
      source  = "hashicorp/zillaforge"
      version = "0.0.1-alpha"
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

data "zillaforge_images" "ubuntu_2404" {
  repository = "ubuntu"
  tag        = "2404"
}

data "zillaforge_flavors" "basic_small" {
  name = "Basic.small"
}

data "zillaforge_networks" "default" {
  name = "default"
}

data "zillaforge_security_groups" "selected" {
  name = var.sg_name
}

data "zillaforge_keypairs" "selected" {
  name = var.keypair_name
}

# ---------------------------------------------------------------------------
# Floating IP
# ---------------------------------------------------------------------------

resource "zillaforge_floating_ip" "vm_fip" {
  name        = "ubuntu-2404-fip"
  description = "Floating IP for Ubuntu 24.04 VM"
}

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

resource "zillaforge_server" "ubuntu_2404" {
  name      = "ubuntu-2404-vm"
  flavor_id = data.zillaforge_flavors.basic_small.flavors[0].id
  image_id  = data.zillaforge_images.ubuntu_2404.images[0].id
  keypair   = data.zillaforge_keypairs.selected.keypairs[0].id

  network_attachment {
    network_id         = data.zillaforge_networks.default.networks[0].id
    primary            = true
    security_group_ids = [data.zillaforge_security_groups.selected.security_groups[0].id]
    floating_ip_id     = zillaforge_floating_ip.vm_fip.id
  }

  wait_for_active = true
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "server_id" {
  value = zillaforge_server.ubuntu_2404.id
}

output "server_private_ip" {
  value = zillaforge_server.ubuntu_2404.ip_addresses
}

output "server_floating_ip" {
  value = zillaforge_server.ubuntu_2404.network_attachment[0].floating_ip
}