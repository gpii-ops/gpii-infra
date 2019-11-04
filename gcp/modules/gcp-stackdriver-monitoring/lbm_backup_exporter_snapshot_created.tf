resource "google_logging_metric" "backup_exporter_snapshot_created" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "backup_exporter.snapshot_created"
  filter     = "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"k8s-cluster\" AND resource.labels.namespace_name=\"backup-exporter\" AND resource.labels.container_name=\"backup-container\" AND textPayload=\"[Daisy] All workflows completed successfully.\n\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
