terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "nonce" {}

variable "sa_id" {
  default = "gke-cluster-pod-default" 
}

resource "kubernetes_namespace" "gpii" {
  metadata {
    name = "gpii"

    labels {
      istio-injection = "enabled"
    }
  }
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
