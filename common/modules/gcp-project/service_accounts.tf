# GKE node service account used by nodes and service-account-assigner
resource "google_service_account" "gke_cluster_node" {
  account_id   = "gke-cluster-node"
  display_name = "gke-cluster-node"
  project      = "${google_project.project.project_id}"
}

# Default service account for pods
resource "google_service_account" "gke_cluster_pod_default" {
  account_id   = "gke-cluster-pod-default"
  display_name = "gke-cluster-pod-default"
  project      = "${google_project.project.project_id}"
}
