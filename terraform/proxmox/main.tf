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
