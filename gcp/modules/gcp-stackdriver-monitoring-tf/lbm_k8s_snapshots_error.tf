resource "google_logging_metric" "k8s_snapshots_error" {
  name   = "k8s_snapshots.error"
  filter = "resource.type=\"k8s_container\" AND resource.labels.container_name=\"k8s-snapshots\" AND textPayload:\"Error: \""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
