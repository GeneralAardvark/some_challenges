resource "google_storage_bucket" "wordpress_storage" {
  name     = "${var.gcp_project}-${var.envname}-wordpress-storage"
  location = "EU"
}

resource "google_storage_bucket" "bootstrap_storage" {
  name     = "${var.gcp_project}-${var.envname}-bootstrap"
  location = "EU"
}

resource "google_storage_bucket_object" "bootstrap_script" {
  bucket  = google_storage_bucket.bootstrap_storage.name
  name    = "bootstrap.sh"
  content = file("include/bootstrap.sh")
}

resource "google_storage_bucket_object" "nfs_bootstrap_script" {
  bucket  = google_storage_bucket.bootstrap_storage.name
  name    = "nfs-bootstrap.sh"
  content = file("include/nfs-bootstrap.sh")
}

output "wordpress_storage_bucket" {
  value = google_storage_bucket.wordpress_storage.name
}
