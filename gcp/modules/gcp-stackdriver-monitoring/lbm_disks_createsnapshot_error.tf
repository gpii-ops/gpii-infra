resource "google_logging_metric" "disks_createsnapshot_error" {
  name       = "compute.disks.createSnapshot.error"
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  filter     = "resource.type=\"gce_disk\" AND protoPayload.methodName=\"v1.compute.disks.createSnapshot\" AND severity=\"ERROR\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
