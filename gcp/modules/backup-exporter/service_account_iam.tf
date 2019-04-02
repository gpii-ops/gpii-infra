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

resource "google_storage_bucket_iam_binding" "member" {
  bucket = "${google_storage_bucket.backup_daisy_bkt.name}"
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com",
  ]
}

resource "google_storage_bucket_iam_binding" "owner" {
  bucket = "${google_storage_bucket.backup_daisy_bkt.name}"
  role   = "roles/storage.admin"

  members = [
    "user:alfredo@raisingthefloor.org",
  ]
}
