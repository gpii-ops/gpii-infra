terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}

# Terragrunt variables
variable "node_type" {}

variable "prevent_destroy_cluster" {
  default = false
}

module "gke_cluster" {
  source             = "/exekube-modules/gke-cluster"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"

  initial_node_count = 1
  node_type          = "${var.node_type}"
  kubernetes_version = "1.10.9-gke.3"

  main_compute_zone = "us-central1-a"
  additional_zones  = ["us-central1-b", "us-central1-c", "us-central1-f"]

  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  oauth_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/trace.append",
  ]

  dashboard_disabled = true

  # empty password and username disables legacy basic authentication
  master_auth_username = ""
  master_auth_password = ""

  issue_client_certificate = false

  update_timeout = "30m"
}

# Workaround from
# https://github.com/hashicorp/terraform/issues/3116#issuecomment-292038781
# to allow us to optionally enable 'lifecycle { prevent_destroy = true }'.
resource "random_id" "cluster_protector" {
  count       = "${var.prevent_destroy_cluster ? 1 : 0}"
  byte_length = 8

  keepers = {
    protected_resources = "${module.gke_cluster.stub_output_for_dependency}"
  }

  lifecycle {
    # If you are sure you want to destroy a cluster (e.g. to re-create it from
    # scratch or to change a parameter like 'oauth_scopes' that requires
    # cluster re-creation):
    #
    # * Change the value below to 'false'
    # * Destroy the cluster
    # * Change the value below back to 'true'
    prevent_destroy = false
  }
}
