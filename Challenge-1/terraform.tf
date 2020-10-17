terraform {
  required_version = ">= 0.13.4"

  backend "gcs" {
    bucket = "PROJECT_tfstate"
    prefix = "ENV"
  }
}

provider "google" {
  project      = var.gcp_project
  region       = var.gcp_region
  access_token = var.access_token

  user_project_override = true
}

provider "google-beta" {
  project      = var.gcp_project
  region       = var.gcp_region
  access_token = var.access_token

  user_project_override = true
}
