output "name_servers" {
  description = "The authoritative Google Cloud DNS name servers for domain delegation."
  value       = google_dns_managed_zone.primary.name_servers
}

output "dns_zone_name" {
  description = "The name of the Cloud DNS managed zone."
  value       = google_dns_managed_zone.primary.name
}

output "dns_name" {
  description = "The DNS name configured for the zone."
  value       = google_dns_managed_zone.primary.dns_name
}

output "pve_api_token_secret_id" {
  description = "The Secret Manager secret ID for Proxmox VE API token."
  value       = google_secret_manager_secret.pve_api_token.secret_id
}

