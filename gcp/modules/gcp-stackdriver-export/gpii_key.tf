provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

resource "google_bigquery_dataset" "this" {
  dataset_id = "exported_logs_with_gpii_key"
  location   = "US"
}

resource "google_logging_project_sink" "this" {
  name        = "gpii-key"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.this.dataset_id}"
  filter      = "textPayload:\"gpiiKey: '\" AND resource.type=\"k8s_container\" AND (resource.labels.container_name=\"preferences\" OR resource.labels.container_name=\"flowmanager\")"

  unique_writer_identity = true
}

resource "google_project_iam_member" "this" {
  member = "${google_logging_project_sink.this.writer_identity}"
  role   = "roles/bigquery.dataEditor"
}
