resource "google_logging_metric" "backup-exporter_snapshot_created" {
  count  = "${length(local.common_environments)}"
  name   = "backup-exporter.snapshot_created_${element(local.common_environments, count.index)}"
  filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"gpii-backup-${element(local.common_environments, count.index)}\" AND resource.labels.location=\"us\" AND protoPayload.methodName=\"storage.objects.create\""
}
