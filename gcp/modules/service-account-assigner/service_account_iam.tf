data "google_service_account" "gke_cluster_node" {
  account_id = "gke-cluster-node"
  project    = "${var.project_id}"
}

data "google_service_account" "gke_cluster_pod_default" {
  account_id = "gke-cluster-pod-default"
  project    = "${var.project_id}"
}

data "google_iam_policy" "pod_default" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "serviceAccount:${data.google_service_account.gke_cluster_node.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "pod_default_iam" {
  service_account_id = "${data.google_service_account.gke_cluster_pod_default.name}"
  policy_data        = "${data.google_iam_policy.pod_default.policy_data}"
}
