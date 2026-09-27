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
  endpoint  = "https://pve-1.home.sinsamersuk.net:8006/"
  insecure  = false
  api_token = var.proxmox_api_token

  ssh {
    agent = true
  }
}
