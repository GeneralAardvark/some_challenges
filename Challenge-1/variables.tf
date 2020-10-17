
variable "gcp_project" {}
variable "gcp_region" {}
variable "envname" {}
variable "access_token" {}

variable "project_services" {
  type = list
  default = [
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "iam.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "dns.googleapis.com",
    "sourcerepo.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

variable "repo_name" {}

variable "zone_name" {}
variable "zone_domain" {}

variable "subnetwork_cidr" {}

variable "inbound_cidrs" {
  type = list
  default = []
}

variable "wordpress_machine_type" {
  type = string
  default = "e2-small"
}

variable "nfs_machine_type" {
  type = string
  default = "e2-small"
}

variable "nfs_disk_size" {
  type = number
  default = 50
}

variable "min_replicas" {
  type = number
  default = 1
}
variable "max_replicas" {
  type = number
  default = 1
}

variable "sql_machine_type" {
  type = string
  default = "db-g1-small"
}

variable "database_version" {
  type = string
  default = "MYSQL_5_7"
}

variable "sql_backup_time" {
  type = string
  default = "02:00"
}

variable "maintenance_day" {
  type = string
  default = "1"
}

variable "maintenance_hour" {
  type = string
  default = "7"
}

variable "update_track" {
  type = string
  default = "stable"
}

variable "database_flags" {
  type = list
  default = []
}

variable "database_labels" {
  type = map
  default = {}
}

variable "rolling_update_policy" {
  type = list
  default = [{
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_percent            = null
    min_surge_percent            = null
    max_surge_fixed              = 3
    min_surge_fixed              = null
    max_unavailable_percent      = null
    min_unavailable_percent      = null
    max_unavailable_fixed        = 0
    min_unavailable_fixed        = null
    min_ready_sec                = null
  }]
}

variable "packer_json" {
  type = string
  default = "SHORTNAME-debian10.json"
}
