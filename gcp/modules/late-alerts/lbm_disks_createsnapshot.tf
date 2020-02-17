resource "google_logging_metric" "disks_createsnapshot" {
  project = "${var.project_id}"
  name    = "compute.disks.createSnapshot"
  filter  = "resource.type=\"gce_disk\" AND protoPayload.methodName=\"v1.compute.disks.createSnapshot\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"

    labels = [
      {
        key        = "pv_name"
        value_type = "STRING"
      },
      {
        key        = "severity"
        value_type = "STRING"
      },
    ]
  }

  label_extractors = {
    "pv_name"  = "REGEXP_EXTRACT(protoPayload.request.description, \".*\\\"name.:..([^\\\"]+).*\")"
    "severity" = "EXTRACT(severity)"
  }
}
