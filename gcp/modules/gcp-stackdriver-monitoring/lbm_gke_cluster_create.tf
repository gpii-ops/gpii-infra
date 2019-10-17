resource "google_logging_metric" "gke_cluster_create" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "gke_cluster.create"
  filter     = "resource.type=\"gke_cluster\" AND protoPayload.methodName:\"ClusterManager.CreateCluster\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
