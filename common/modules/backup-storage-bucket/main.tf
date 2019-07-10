terraform {
  backend "gcs" {}
}

variable "cloudbuild_sa" {}
variable "backup_storage_bucket_name" {}
variable "project_id" {}
variable "infra_region" {}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "${var.infra_region}"
}

resource "google_storage_bucket" "backup_external" {
  project       = "${var.project_id}"
  name          = "${var.backup_storage_bucket_name}"
  force_destroy = false
}

resource "google_storage_bucket_iam_binding" "backup_admin" {
  bucket = "${google_storage_bucket.backup_external.name}"
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${var.cloudbuild_sa}",
  ]
}
