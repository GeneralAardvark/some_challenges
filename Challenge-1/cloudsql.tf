locals {
  the_network_id = var.envname == "dev" ? google_compute_network.network.0.id : data.google_compute_network.network.id
}

resource "google_sql_database_instance" "primary" {

  #  name = "myinstance" DON'T NAME A DATABASE AS IT CAN'T BE RE-USED FOR 2 MONTHS!!!
  database_version = var.database_version
  region           = var.gcp_region
  project          = var.gcp_project

  depends_on = [ local.the_network_id ]

  settings {
    tier = var.sql_machine_type

    disk_type       = "PD_SSD"
    disk_autoresize = true

    backup_configuration {
      binary_log_enabled = true
      enabled            = true
      start_time         = var.sql_backup_time
    }

    maintenance_window {
      day          = var.maintenance_day
      hour         = var.maintenance_hour
      update_track = var.update_track
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.envname == "dev" ? google_compute_network.network.0.self_link : data.google_compute_network.network.self_link
      require_ssl     = false

      dynamic "authorized_networks" {
        for_each = var.inbound_cidrs
        iterator = inbound_cidrs

        content {
          value = inbound_cidrs.value
        }
      }
    }

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    user_labels = var.database_labels
  }
}

resource "google_sql_database_instance" "failover" {
  count = var.envname == "prod" ? 1 : 0

  database_version     = var.database_version
  region               = var.gcp_region
  master_instance_name = google_sql_database_instance.primary.name

  settings {
    tier = var.sql_machine_type

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.envname == "dev" ? google_compute_network.network.0.self_link : data.google_compute_network.network.self_link
      require_ssl     = false
    }

    disk_type       = "PD_SSD"
    disk_autoresize = true

    maintenance_window {
      day          = var.maintenance_day
      hour         = var.maintenance_hour
      update_track = var.update_track
    }

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    crash_safe_replication = true
  }

  replica_configuration {
    failover_target = true
  }
}

data "google_secret_manager_secret_version" "db_password" {
  secret = "${var.envname}-db-password"
}

resource "google_sql_database" "database" {
  name     = "wordpress"
  instance = google_sql_database_instance.primary.name

  depends_on = [google_project_service.service]
}

resource "google_sql_user" "users" {
  name     = "wp_user"
  instance = google_sql_database_instance.primary.name
  host     = "%"
  password = data.google_secret_manager_secret_version.db_password.secret_data

  depends_on = [google_project_service.service]
}

resource "google_dns_record_set" "db_dns" {

  name         = "db.${var.envname}.${var.zone_domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.env_zone.name
  rrdatas      = [google_sql_database_instance.primary.private_ip_address]
}

