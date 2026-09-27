terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.68.0"
    }
  }

  backend "gcs" {
    bucket      = "sinsamersuk-homelab-tfstate"
    prefix      = "terraform/state/proxmox"
    credentials = "../gcp/credentials.json"
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  # Supports either API Token (recommended) or Username & Password
  api_token = var.proxmox_api_token
  username  = var.proxmox_username
  password  = var.proxmox_password

  ssh {
    agent = true
  }
}
