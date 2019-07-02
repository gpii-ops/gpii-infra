variable "service_account_id" {
  default = "gke-cluster-pod-flowmanager"
}

data "google_service_account" "service_account" {
  account_id = "${var.service_account_id}"
  project    = "${var.project_id}"
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = "${data.google_service_account.service_account.name}"
}

resource "kubernetes_secret" "service_account_credentials" {
  metadata = {
    name      = "${var.service_account_id}-credentials"
    namespace = "gpii"
  }

  data {
    credentials.json = "${base64decode(google_service_account_key.service_account_key.private_key)}"
  }
}
