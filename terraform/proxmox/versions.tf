terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.68.0"
    }
  }

  # Uncomment after creating your private GCS bucket in GCP:
  # backend "gcs" {
  #   bucket = "YOUR_UNIQUE_TF_STATE_BUCKET"
  #   prefix = "terraform/state/proxmox"
  # }
}
