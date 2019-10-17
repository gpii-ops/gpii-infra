resource "google_logging_metric" "backup_exporter_error" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "backup_exporter.error"
  filter     = "resource.type=\"k8s_container\" AND resource.labels.cluster_name=\"k8s-cluster\" AND resource.labels.namespace_name=\"backup-exporter\" AND resource.labels.container_name=\"backup-container\" AND severity=ERROR AND (textPayload:\"ERROR:\" OR textPayload:\"CommandException:\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
