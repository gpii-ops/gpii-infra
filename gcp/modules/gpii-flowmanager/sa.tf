variable "sa_id" {
  default = "gke-cluster-pod-flowmanager"
}

data "google_service_account" "sa" {
  account_id = "${var.sa_id}"
  project    = "${var.project_id}"
}

resource "google_service_account_key" "sa_key" {
  service_account_id = "${data.google_service_account.sa.name}"
}

resource "kubernetes_secret" "sa_credentials" {
  metadata = {
    name      = "${var.sa_id}-credentials"
    namespace = "gpii"
  }

  data {
    credentials.json = "${base64decode(google_service_account_key.sa_key.private_key)}"
  }
}
