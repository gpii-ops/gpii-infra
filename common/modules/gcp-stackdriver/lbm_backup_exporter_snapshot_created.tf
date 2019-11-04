resource "google_logging_metric" "backup_exporter_snapshot_created" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  count      = "${length(var.common_environments)}"
  name       = "backup-exporter.snapshot_created_${element(var.common_environments, count.index)}"
  filter     = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"gpii-backup-${element(var.common_environments, count.index)}\" AND resource.labels.location=\"us\" AND protoPayload.methodName=\"storage.objects.create\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
