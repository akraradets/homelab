# ==============================================================================
# Google Cloud Secret Manager Containers for Homelab Credentials
#
# GCP Always Free Tier Budget Constraint:
# - Up to 6 active secret versions per billing account are 100% FREE.
# - Up to 10,000 secret access operations / month are 100% FREE.
#
# Secret Inventory (Current: 1 / 6 Active Versions):
# 1. pve-api-token (Proxmox VE API Token for Terraform automation)
# ==============================================================================

# Secret container for Proxmox VE API Token (payload added out-of-band via gcloud)
resource "google_secret_manager_secret" "pve_api_token" {
  secret_id = "pve-api-token"

  labels = {
    environment = "homelab"
    managed_by  = "terraform"
    service     = "proxmox"
  }

  replication {
    auto {}
  }
}
