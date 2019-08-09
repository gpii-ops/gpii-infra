terraform {
  backend "gcs" {}
}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "${var.infra_region}"
}

resource "null_resource" "retention_policy" {
  triggers = {
    days_until_delete = "${var.days_until_delete}"
  }

  provisioner "local-exec" {
    command = "gsutil retention set ${var.days_until_delete}d ${google_storage_bucket.external-backup-store.url}"
  }
}

resource "google_storage_bucket" "external-backup-store" {
  name     = "gpii-backup-${var.source_project_name}"
  location = "${var.location}"
  project  = "${var.project_id}"

  # The Storage class is NEARLINE for less than 30 days of living period and
  # COLDLINE for more.
  storage_class = "${var.days_until_delete < 30 ? "NEARLINE" : "COLDLINE"}"

  lifecycle_rule = {
    action = {
      type = "Delete"
    }

    condition = {
      age = "${var.days_until_delete}"
    }
  }
}

resource "google_storage_bucket_iam_binding" "member" {
  # WARNING: the backup exporter must be installed in the source project in
  # order to have the service account gke-cluster-pod-bckp-exporter. As the
  # deployment of that module will be performed after this module, the 'count'
  # variable must be set to 0 the first time. Then it should be 1 in order to
  # apply this IAM binding.
  count = 1

  bucket = "${google_storage_bucket.external-backup-store.name}"
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:gke-cluster-pod-bckp-exporter@gpii-gcp-${var.source_project_name}.iam.gserviceaccount.com",
  ]
}
