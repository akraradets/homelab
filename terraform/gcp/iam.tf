# ==============================================================================
# Service Account for Proxmox VE ACME DNS-01 Challenges
# ==============================================================================

resource "google_service_account" "pve_acme" {
  account_id   = "pve-acme"
  display_name = "Proxmox ACME DNS Challenge"
  description  = "Dedicated service account for Proxmox VE ACME DNS-01 challenges"
}

# Grant DNS Administrator role to create and delete ACME TXT records
resource "google_project_iam_member" "pve_acme_dns_admin" {
  project = "sinsamersuk"
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.pve_acme.email}"
}

# Generate Service Account Key for Proxmox
resource "google_service_account_key" "pve_acme_key" {
  service_account_id = google_service_account.pve_acme.name
}

# Save local copy (git-ignored: *sa*.json) to transfer to Proxmox
resource "local_file" "pve_acme_key" {
  content         = base64decode(google_service_account_key.pve_acme_key.private_key)
  filename        = "${path.module}/pve-acme-sa.json"
  file_permission = "0600"
}
