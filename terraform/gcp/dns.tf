# ==============================================================================
# Google Cloud DNS - sinsamersuk.net Managed Zone & Records
# ==============================================================================

locals {
  dns_zone_name = "sinsamersuk-net"
  domain_name   = "sinsamersuk.net."

  # Active DNS Records
  records = [
    {
      name    = "authen.sinsamersuk.net."
      type    = "CNAME"
      ttl     = 300
      rrdatas = ["www.sinsamersuk.com."]
    },
    {
      name    = "traefik.sinsamersuk.net."
      type    = "CNAME"
      ttl     = 300
      rrdatas = ["www.sinsamersuk.com."]
    },
    {
      name    = "pve-1.home.sinsamersuk.net."
      type    = "A"
      ttl     = 300
      rrdatas = ["192.168.55.10"]
    },
    {
      name    = "truenas.home.sinsamersuk.net."
      type    = "A"
      ttl     = 300
      rrdatas = ["192.168.55.100"]
    },
    {
      name    = "desktop.home.sinsamersuk.net."
      type    = "A"
      ttl     = 300
      rrdatas = ["192.168.55.110"]
    }
  ]
}

# Public Authoritative Managed Zone
resource "google_dns_managed_zone" "primary" {
  name        = local.dns_zone_name
  dns_name    = local.domain_name
  description = "DNS zone for domain: sinsamersuk.net"
  visibility  = "public"

  dnssec_config {
    state = "on"
  }
}

# Configured DNS Records
resource "google_dns_record_set" "records" {
  for_each = { for r in local.records : "${r.name}_${r.type}" => r }

  managed_zone = google_dns_managed_zone.primary.name
  name         = each.value.name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.rrdatas
}
