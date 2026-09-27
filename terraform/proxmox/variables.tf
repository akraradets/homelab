# ==============================================================================
# Proxmox VE Terraform Variables
# Populated via scripts/bootstrap.sh into local terraform.tfvars
# ==============================================================================

variable "proxmox_api_token" {
  type        = string
  description = "The Proxmox VE API token retrieved from GCP Secret Manager (root@pam!terraform=UUID)."
  sensitive   = true
}
