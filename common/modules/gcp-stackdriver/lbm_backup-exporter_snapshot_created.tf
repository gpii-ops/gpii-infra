resource "google_logging_metric" "backup-exporter_snapshot_created_stg" {
  name   = "backup-exporter.snapshot_created_stg"
  filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"gpii-backup-stg\" AND resource.labels.location=\"us\" AND protoPayload.methodName=\"storage.objects.create\""
}

resource "google_logging_metric" "backup-exporter_snapshot_created_prd" {
  name   = "backup-exporter.snapshot_created_prd"
  filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"gpii-backup-prd\" AND resource.labels.location=\"us\" AND protoPayload.methodName=\"storage.objects.create\""
}
