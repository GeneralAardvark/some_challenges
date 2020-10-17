data "google_compute_zones" "zones" {
  region = var.gcp_region
  status = "UP"
}

locals {
  nfs_zones = slice(data.google_compute_zones.zones.names, 0, 2)
}

resource "google_compute_region_disk" "nfs-disk" {
  name                      = "nfs-${var.envname}"
  type                      = "pd-ssd"
  region                    = var.gcp_region
  size                      = var.nfs_disk_size
  physical_block_size_bytes = 4096

  replica_zones = local.nfs_zones
}

module "nfs_instance_template" {
  source = "terraform-google-modules/vm/google//modules/instance_template"
  version = "5.1.0"

  name_prefix  = "nfs-${var.envname}"
  machine_type = var.nfs_machine_type

  disk_size_gb         = 10
  disk_type            = "pd-ssd"
  source_image_family  = "debian-10"
  source_image_project = "debian-cloud"

  metadata = {
    envname            = var.envname
    profile            = "nfs"
    domain             = "${var.envname}.${var.zone_domain}"
    disk_name          = google_compute_region_disk.nfs-disk.name
    startup-script-url = "gs://${var.gcp_project}-${var.envname}-bootstrap/nfs-bootstrap.sh"
  }

  subnetwork = data.google_compute_subnetwork.subnetwork.name
  tags = [
    var.envname,
    "nfs"
  ]

  labels = {
    envname  = var.envname
    profile  = "nfs"
  }

  service_account = {
    email = null
    scopes = [
      "storage-rw",
      "compute-rw",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite"
    ]
  }
}

module "nfs_instance_group" {
  source = "terraform-google-modules/vm/google//modules/mig"
  version = "5.1.0"

  project_id        = var.gcp_project
  hostname          = "nfs-${var.envname}"
  instance_template = module.nfs_instance_template.self_link

  subnetwork                = data.google_compute_subnetwork.subnetwork.name
  region                    = var.gcp_region
  distribution_policy_zones = local.nfs_zones

  target_size = 1
}

