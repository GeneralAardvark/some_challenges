module "vm_instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "5.1.0"

  name_prefix = "wordpress-${var.envname}"
  machine_type = var.wordpress_machine_type

  disk_size_gb         = 10
  disk_type            = "pd-ssd"
  source_image_family  = "SHORTNAME-${var.envname}-debian10-wordpress"
  source_image_project = var.gcp_project

  subnetwork = data.google_compute_subnetwork.subnetwork.name
  tags = [
    var.envname,
    "wordpress"
  ]

  metadata = {
    envname = var.envname
    profile = "wordpress"
    domain  = "${var.envname}.${var.zone_domain}"
    startup-script-url = "gs://${var.gcp_project}-${var.envname}-bootstrap/bootstrap.sh"
  }

  labels = {
    envname = var.envname
    profile = "wordpress"
  }

  service_account = {
    email = null
    scopes = [
      "storage-rw",
      "compute-ro",
      "logging-write",
      "monitoring-write",
      "cloud-platform",
      "sql-admin",
      ]
    }
}

module "vm_mig" {
  source  = "terraform-google-modules/vm/google//modules/mig"
  version = "5.1.0"

  project_id = var.gcp_project

  hostname = "wordpress-${var.envname}"
  instance_template = module.vm_instance_template.self_link

  named_ports = [{
    name = "http",
    port = 80
  }]

  autoscaling_enabled = true
  min_replicas = var.min_replicas
  max_replicas = var.max_replicas
  autoscaling_cpu = [{
    target = 0.6
  }]

  region = var.gcp_region
  subnetwork = data.google_compute_subnetwork.subnetwork.name

  update_policy = var.rolling_update_policy
}
