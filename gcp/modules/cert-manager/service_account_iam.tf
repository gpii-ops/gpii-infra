data "google_service_account" "gke_cluster_node" {
  account_id = "gke-cluster-node"
  project    = "${var.project_id}"
}

data "google_service_account" "gke_cluster_pod_cert_manager" {
  account_id = "gke-cluster-pod-cert-manager"
  project    = "${var.project_id}"
}

data "google_iam_policy" "gke_cluster_pod_cert_manager" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "serviceAccount:${data.google_service_account.gke_cluster_node.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "cert_manager_iam" {
  service_account_id = "${data.google_service_account.gke_cluster_pod_cert_manager.name}"
  policy_data        = "${data.google_iam_policy.gke_cluster_pod_cert_manager.policy_data}"
}
