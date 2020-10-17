resource "google_dns_managed_zone" "primary_zone" {
  count = var.envname == "dev" ? 1 : 0

  name        = var.zone_name
  dns_name    = "${var.zone_domain}."
  description = "DNS Zone created and Managed by Terraform"
}

resource "google_dns_managed_zone" "env_zone" {
  name        = "${var.envname}-${var.zone_name}"
  dns_name    = "${var.envname}.${var.zone_domain}."
  description = "DNS Zone created and Managed by Terraform"
}

data "google_dns_managed_zone" "primary_zone" {
  count = var.envname == "prod" ? 1: 0

  name = var.zone_name

  depends_on = [google_dns_managed_zone.primary_zone]
}

resource "google_dns_record_set" "ns" {
  name         = "${var.envname}.${var.zone_domain}."
  managed_zone = var.envname == "prod" ? data.google_dns_managed_zone.primary_zone.0.name : google_dns_managed_zone.primary_zone.0.name
  type         = "NS"
  ttl          = "21600"
  rrdatas      = google_dns_managed_zone.env_zone.name_servers
}

output "name_serves" {
  value = var.envname == "dev" ? google_dns_managed_zone.primary_zone.0.name_servers : [""]
}
