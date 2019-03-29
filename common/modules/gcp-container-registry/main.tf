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

resource "google_service_account" "gcr_uploader" {
  account_id   = "gcr-uploader"
  display_name = "gcr-uploader"
}

# GCR stores data in a Google Storage bucket. The name of this bucket is
# prescribed by Google. However, if we try to create the bucket ourselves (e.g.
# with a 'google_storage_bucket' resource), we get 'Error 403: The bucket you
# tried to create requires domain ownership verification.'
#
# Instead, we must let Google create the bucket for us by pushing to the
# Registry. We handle this as a manual one-time step -- see XXX.
#
# We let Google create the bucket and manage its settings. We use the IAM
# bindings below to control read and write access to the bucket (and hence to
# the Registry).
resource "google_storage_bucket_iam_binding" "gcr_uploader" {
  bucket = "artifacts.${var.project_id}.appspot.com"
  role   = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.gcr_uploader.email}",
  ]
}

resource "google_storage_bucket_iam_member" "public_readable" {
  bucket = "artifacts.${var.project_id}.appspot.com"
  role   = "roles/storage.objectViewer"

  member = "allUsers"
}
