# ==============================================================================
# Google Cloud Secret Manager Containers for Homelab Credentials
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
