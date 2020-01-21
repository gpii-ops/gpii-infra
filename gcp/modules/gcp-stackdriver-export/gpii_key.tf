# The resources below are temporary and needed so we can collect
# and analyze some data about individual GPII keys usage.
# More info: https://issues.gpii.net/browse/GPII-4158

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

resource "google_bigquery_dataset" "gpii_key" {
  dataset_id = "exported_logs_with_gpii_key"
  location   = "US"

  delete_contents_on_destroy = "${var.env == "dev" ? true : false}"
}

resource "google_logging_project_sink" "gpii_key" {
  name        = "gpii-key"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.gpii_key.dataset_id}"
  filter      = "textPayload:\"gpiiKey: '\" AND resource.type=\"k8s_container\" AND (resource.labels.container_name=\"preferences\" OR resource.labels.container_name=\"flowmanager\")"
}
