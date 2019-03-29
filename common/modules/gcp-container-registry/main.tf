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
  # Google prescribes the name of this bucket.
  registry_bucket = "artifacts.${var.project_id}.appspot.com"
}

resource "google_service_account" "gcr_uploader" {
  account_id   = "gcr-uploader"
  display_name = "gcr-uploader"
}

# GCR stores data in a Google Storage bucket. However, if we try to create the
# bucket ourselves (e.g.  with a 'google_storage_bucket' resource), we get
# 'Error 403: The bucket you tried to create requires domain ownership
# verification.'
#
# Instead, we must let Google create the bucket for us by pushing to the
# Registry. We handle this as an extra CI step -- see `rake init_registry`.
#
# We let Google create the bucket and manage its settings. We use the IAM
# bindings below to control read and write access to the bucket (and hence to
# the Registry).
resource "google_storage_bucket_iam_binding" "gcr_uploader" {
  bucket = "${local.registry_bucket}"
  role   = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.gcr_uploader.email}",
  ]
}

resource "google_storage_bucket_iam_member" "public_readable" {
  bucket = "${local.registry_bucket}"
  role   = "roles/storage.objectViewer"

  member = "allUsers"
}
