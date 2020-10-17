resource "google_sourcerepo_repository" "code-repo" {
  count = var.envname == "dev" ? 1 : 0

  name = var.repo_name
}
