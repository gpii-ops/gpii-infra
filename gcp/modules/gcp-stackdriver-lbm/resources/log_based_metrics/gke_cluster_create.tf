resource "google_logging_metric" "gke_cluster_create" {
  name   = "gke_cluster.create"
  filter = "resource.type=\"gke_cluster\" AND protoPayload.methodName:\"ClusterManager.CreateCluster\""
}
