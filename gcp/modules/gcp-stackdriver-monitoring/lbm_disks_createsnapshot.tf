resource "google_logging_metric" "disks_createsnapshot" {
  name       = "compute.disks.createSnapshot"
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  filter     = "resource.type=\"gce_disk\" AND protoPayload.methodName=\"v1.compute.disks.createSnapshot\""

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
    "pv_name"  = "EXTRACT(protoPayload.request.name)"
    "severity" = "EXTRACT(severity)"
  }
}
