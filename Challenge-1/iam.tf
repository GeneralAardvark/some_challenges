data "google_project" "project" {
}

resource "google_project_iam_member" "secret_access" {
  project = var.gcp_project
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "build_access" {
  project = var.gcp_project
  role = "roles/editor"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "build_secret_access" {
  project = var.gcp_project
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

