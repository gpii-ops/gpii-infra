terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}

# Terragrunt variables
variable "node_type" {}

module "gke_cluster" {
  source             = "/exekube-modules/gke-cluster"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"

  initial_node_count = 1
  node_type          = "${var.node_type}"
  kubernetes_version = "1.10.7-gke.2"

  main_compute_zone = "us-central1-a"
  additional_zones  = ["us-central1-b", "us-central1-c", "us-central1-f"]

  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  oauth_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
  ]

  dashboard_disabled = true

  # empty password and username disables legacy basic authentication
  master_auth_username = ""
  master_auth_password = ""

  issue_client_certificate = false

  update_timeout = "30m"
}
