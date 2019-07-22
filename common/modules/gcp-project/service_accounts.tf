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

# Service account for backup exporter cronjob
resource "google_service_account" "gke_cluster_pod_backup_exporter" {
  account_id   = "gke-cluster-pod-bckp-exporter"
  display_name = "gke-cluster-pod-backup-exporter"
  project      = "${google_project.project.project_id}"
}

# cert-manager SVC account for DNS challenge
resource "google_service_account" "gke_cluster_pod_cert_manager" {
  account_id   = "gke-cluster-pod-cert-manager"
  display_name = "gke-cluster-pod-cert-manager"
  project      = "${google_project.project.project_id}"
}

# k8s-snapshots SVC account with access to storage
resource "google_service_account" "gke_cluster_pod_k8s_snapshots" {
  account_id   = "gke-cluster-pod-k8s-snapshots"
  display_name = "gke-cluster-pod-k8s-snapshots"
  project      = "${google_project.project.project_id}"
}

# Since we sometimes use ADCs, and since the binaryauthorization API does not
# allow ADCs, we need a dedicated SA to manage binary auth. See GPII-3860.
resource "google_service_account" "gke_cluster_bin_auth" {
  account_id   = "gke-cluster-bin-auth"
  display_name = "gke-cluster-bin-auth"
  project      = "${google_project.project.project_id}"
}
