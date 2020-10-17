
envname = "prod"
gcp_project = "PROJECT"
gcp_region = "europe-west2"

zone_name = "SHORTNAME"
zone_domain = "SUBDOMAIN"

subnetwork_cidr = "172.16.4.0/24"

database_labels = {
  "envname" = "prod"
}

repo_name = "PROJECT_source"

rolling_update_policy = [{
  type                         = "OPPORTUNISTIC"
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

