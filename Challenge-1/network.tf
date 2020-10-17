resource "google_compute_network" "network" {
  count = var.envname == "dev" ? 1 : 0

  name                    = "project-network"
  auto_create_subnetworks = false
  lifecycle {
    create_before_destroy = true
  }
}

data "google_compute_network" "network" {
  name = "project-network"
}

data "google_compute_subnetwork" "subnetwork" {
  name = "${var.envname}-subnetwork"
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${var.envname}-subnetwork"
  ip_cidr_range = var.subnetwork_cidr
  network       = data.google_compute_network.network.name
  region        = var.gcp_region
}

resource "google_compute_route" "public_default" {
  count = var.envname == "dev" ? 1 : 0

  name                   = "${var.envname}-public-subnetwork-default-route"
  dest_range             = "0.0.0.0/0"
  network                = data.google_compute_network.network.name
  next_hop_gateway       = "projects/${var.gcp_project}/global/gateways/default-internet-gateway"
  priority               = 500
}

module "nat" {
  source = "terraform-google-modules/cloud-nat/google"

  project_id = var.gcp_project
  region     = var.gcp_region

  create_router                      = true
  router                             = "nat-gw-${var.envname}"
  network                            = data.google_compute_network.network.name
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetworks = [{
    name                     = data.google_compute_subnetwork.subnetwork.name
    source_ip_ranges_to_nat  = ["PRIMARY_IP_RANGE"]
    secondary_ip_range_names = []
  }]
}

resource "google_compute_global_address" "private_ip_address" {
  count = var.envname == "dev" ? 1 : 0

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.envname == "dev" ? 1 : 0

  network                 = data.google_compute_network.network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.0.name]
}


