resource "google_compute_global_address" "lb-ip" {
  name = "${var.envname}-lb-ip"
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  provider = google-beta

  name = "wordpress-${var.envname}"

  managed {
    domains = ["wordpress.${var.envname}.${var.zone_domain}."]
  }
}

resource "google_compute_target_https_proxy" "proxy" {
  provider = google-beta

  name             = "wordpress-${var.envname}-proxy"
  url_map          = google_compute_url_map.urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert.id]
}

resource "google_compute_target_http_proxy" "http_proxy" {
  provider = google-beta

  name             = "wordpress-${var.envname}-http-proxy"
  url_map          = google_compute_url_map.urlmap.id
}

resource "google_compute_url_map" "urlmap" {
  provider = google-beta

  name        = "${var.envname}-url-map"

  default_service = google_compute_backend_service.wordpress_backend.id

  host_rule {
    hosts        = ["wordpress.${var.envname}.${var.zone_domain}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.wordpress_backend.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.wordpress_backend.id
    }
  }
}

resource "google_compute_backend_service" "wordpress_backend" {
  provider = google-beta

  name        = "${var.envname}-wordpress-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = module.vm_mig.instance_group
  }

  health_checks = [google_compute_http_health_check.healthcheck.id]
}

resource "google_compute_http_health_check" "healthcheck" {
  provider = google-beta

  name               = "${var.envname}-http-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  provider = google-beta

  name       = "${var.envname}-forwarding-rule"
  target     = google_compute_target_https_proxy.proxy.id
  ip_address = google_compute_global_address.lb-ip.address
  port_range = 443
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  provider = google-beta

  name       = "${var.envname}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  ip_address = google_compute_global_address.lb-ip.address
  port_range = 80
}

resource "google_dns_record_set" "set" {
  provider = google-beta

  name         = "wordpress.${var.envname}.${var.zone_domain}."
  type         = "A"
  ttl          = 3600
  managed_zone = google_dns_managed_zone.env_zone.name
  rrdatas      = [google_compute_global_forwarding_rule.forwarding_rule.ip_address]
}
