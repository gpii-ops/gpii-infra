terraform {
  backend "gcs" {}
}

variable "serviceaccount_key" {}

variable "project_id" {}

variable "infra_region" {}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "${var.infra_region}"
}

locals {
  # This won't work for the 'asia' multi-region
  infra_multi_region = "${substr(var.infra_region, 0, 2)}"
}

resource "google_storage_bucket" "registry" {
  # This name is prescribed by Google
  name = "artifacts.${var.project_id}.appspot.com"

  location = "${local.infra_multi_region}"

  force_destroy = false

  versioning = {
    enabled = "false"
  }
}

resource "google_storage_bucket_acl" "public_readable" {
  bucket = "${google_storage_bucket.registry.name}"

  role_entity = [
    "READER:AllUsers",
  ]
}

resource "google_service_account" "gcr_uploader" {
  account_id   = "gcr-uploader"
  display_name = "gcr-uploader"
}

resource "google_storage_bucket_iam_binding" "gcr_uploader" {
  bucket = "${google_storage_bucket.registry.name}"
  role   = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.gcr_uploader.email}",
  ]
}
