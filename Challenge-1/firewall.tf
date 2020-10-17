resource "google_compute_firewall" "public_ssh" {
  name = "${var.envname}-ssh"
  network = var.envname == "dev" ? google_compute_network.network.0.name : data.google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [
    "35.235.240.0/20",   # Cloud-IAP, gcloud ssh tunnelling
  ]

  target_tags = [ var.envname ]
}

resource "google_compute_firewall" "loadbalancer_http" {
  name = "${var.envname}-http"
  network = var.envname == "dev" ? google_compute_network.network.0.name : data.google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [
    "130.211.0.0/22","35.191.0.0/16" # GCP Loadbalancer IPs
  ]

  target_tags = [ var.envname, "wordpress" ]
}

resource "google_compute_firewall" "nfs" {
  name = "${var.envname}-nfs"
  network = var.envname == "dev" ? google_compute_network.network.0.name : data.google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = ["111", "2049"]
  }

  allow {
    protocol = "udp"
    ports    = ["111", "2049"]
  }

  source_tags = [ "wordpress", "nfs" ]
  target_tags = [ "wordpress", "nfs" ]
}
