data "google_service_account" "gke_cluster_node" {
  account_id = "gke-cluster-node"
  project    = "${var.project_id}"
}

data "google_service_account" "gke_cluster_pod_backup_exporter" {
  account_id = "gke-cluster-pod-bckp-exporter"
  project    = "${var.project_id}"
}

data "google_iam_policy" "gke_cluster_pod_backup_exporter" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "serviceAccount:${data.google_service_account.gke_cluster_node.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "pod_default_iam" {
  service_account_id = "${data.google_service_account.gke_cluster_pod_backup_exporter.name}"
  policy_data        = "${data.google_iam_policy.gke_cluster_pod_backup_exporter.policy_data}"
}

# We need to add the SA used by the compute API in order to let cloudbuild make
# changes in the bucket.
resource "google_storage_bucket_iam_binding" "member" {
  bucket = "${google_storage_bucket.backup_daisy_bkt.name}"
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com",
  ]
}
