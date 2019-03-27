data "google_service_account" "gke_cluster_node" {
  account_id = "gke-cluster-node"
  project    = "${var.project_id}"
}

data "google_service_account" "backup_exporter" {
  account_id = "backup-exporter"
  project    = "${var.project_id}"
}

data "google_iam_policy" "backup_exporter" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "serviceAccount:${data.google_service_account.gke_cluster_node.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "pod_default_iam" {
  service_account_id = "${data.google_service_account.backup_exporter.name}"
  policy_data        = "${data.google_iam_policy.backup_exporter.policy_data}"
}
