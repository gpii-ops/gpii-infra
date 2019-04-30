data "google_service_account" "gke_cluster_node" {
  account_id = "gke-cluster-node"
  project    = "${var.project_id}"
}

data "google_service_account" "gke_cluster_pod_k8s_snapshots" {
  account_id = "gke-cluster-pod-k8s-snapshots"
  project    = "${var.project_id}"
}

data "google_iam_policy" "pod_k8s_snapshots" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "serviceAccount:${data.google_service_account.gke_cluster_node.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "pod_k8s_snapshots_iam" {
  service_account_id = "${data.google_service_account.gke_cluster_pod_k8s_snapshots.name}"
  policy_data        = "${data.google_iam_policy.pod_k8s_snapshots.policy_data}"
}
