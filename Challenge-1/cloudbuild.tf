resource "google_cloudbuild_trigger" "image_build" {
  count = var.envname == "dev" ? 1 : 0

  name        = "build-new-image"
  description = "Build new image with packer on changes"

  included_files = ["packer/**"]

  trigger_template {
    branch_name = var.envname
    repo_name = var.repo_name
    dir = "packer"
  }

  build {
    step {
      name = "gcr.io/${var.gcp_project}/packer"
      args = ["build", var.packer_json]
    }
    # The following steps should not be needed, but a bug in the
    # template module means that the MIG won't automatically roll
    # with the new image and we have to terraform plan/apply to
    # propgate the image.
    step {
      name = "ubuntu"
      dir  = "../terraform"
      args = [
        "cp",
        "terraform.tf.${var.envname}",
        "terraform.tf"
      ]
    }
    step {
      name = "hashicorp/terraform:0.13.4"
      dir  = "../terraform"
      args = [
        "init",
        "--upgrade"
      ]
    }
    step {
      name = "hashicorp/terraform:0.13.4"
      dir  = "../terraform"
      args = [
        "plan",
        "-refresh=true",
        "-out=${var.gcp_project}_${var.envname}.plan",
        "-var-file=params/${var.envname}.tfvars",
        "."
      ]
    }
    step {
      name = "hashicorp/terraform:0.13.4"
      dir  = "../terraform"
      args = [
        "apply",
        "${var.gcp_project}_${var.envname}.plan",
      ]
    }
  }
}

resource "google_cloudbuild_trigger" "terraform" {
  name        = "${var.envname}-run-terraform"
  description = "${var.envname} run terraform plan/apply"

  included_files = ["terraform/**"]

  trigger_template {
    branch_name = var.envname
    repo_name = var.repo_name
    dir = "terraform"
  }

  build {
    step {
      name = "ubuntu"
      args = [
        "cp",
        "terraform.tf.${var.envname}",
        "terraform.tf"
      ]
    }
    step {
      name = "hashicorp/terraform:0.13.4"
      args = [
        "init",
        "--upgrade"
      ]
    }
    step {
      name = "hashicorp/terraform:0.13.4"
      args = [
        "plan",
        "-refresh=true",
        "-out=${var.gcp_project}_${var.envname}.plan",
        "-var-file=params/${var.envname}.tfvars"
      ]
    }
    step {
      name = "hashicorp/terraform:0.13.4"
      args = [
        "apply",
        "${var.gcp_project}_${var.envname}.plan",
      ]
    }
  }
}

resource "google_cloudbuild_trigger" "promote_image" {
  count = var.envname == "dev" ? 1 : 0

  name        = "promote-to-prod"
  description = "Use latest disk image in prod MIG"

  disabled = "true"

  trigger_template {
    branch_name = "prod"
    repo_name = var.repo_name
  }

  build {
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "compute",
        "images",
        "create",
        "SHORTNAME-prod-debian10-wordpress-$SHORT_SHA",
        "--source-image-family",
        "SHORTNAME-dev-debian10-wordpress",
        "--family",
        "SHORTNAME-prod-debian10-wordpress"
      ]
    }
    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "compute",
        "instance-groups",
        "managed",
        "rolling-action",
        "replace",
        "wordpress-prod-mig",
        "--region",
        var.gcp_region
      ]
    }
  }
}
