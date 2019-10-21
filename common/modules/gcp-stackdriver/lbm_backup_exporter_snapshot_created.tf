resource "google_logging_metric" "backup_exporter_snapshot_created_prd" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name   = "backup-exporter.snapshot_created_prd"
  filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"gpii-backup-prd\" AND resource.labels.location=\"us\" AND protoPayload.methodName=\"storage.objects.create\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_logging_metric" "backup_exporter_snapshot_created_stg" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name   = "backup-exporter.snapshot_created_prd"
  filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"gpii-backup-stg\" AND resource.labels.location=\"us\" AND protoPayload.methodName=\"storage.objects.create\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
