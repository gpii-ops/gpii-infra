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

# Default service account for pods
resource "google_service_account" "backup_exporter" {
  account_id   = "backup-exporter"
  display_name = "backup-exporter"
  project      = "${google_project.project.project_id}"
  #  count        = "${local.root_project_iam ? 0 : 1}"
}

# k8s-snapshots SVC account with access to storage
resource "google_service_account" "gke_cluster_pod_k8s_snapshots" {
  account_id   = "gke-cluster-pod-k8s-snapshots"
  display_name = "gke-cluster-pod-k8s-snapshots"
  project      = "${google_project.project.project_id}"
}
