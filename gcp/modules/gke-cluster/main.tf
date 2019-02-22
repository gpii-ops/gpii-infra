terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}

# Terragrunt variables
variable "node_type" {}

variable "infra_region" {}

variable "initial_node_count" {
  default = 1
}

variable "prevent_destroy_cluster" {
  default = false
}

module "gke_cluster" {
  source             = "/exekube-modules/gke-cluster"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"

  initial_node_count = "${var.initial_node_count}"
  node_type          = "${var.node_type}"

  kubernetes_version = "1.11.6-gke.3"

  region = "${var.infra_region}"

  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  oauth_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/trace.append",
  ]

  # Istio config
  istio_disabled = false
  istio_auth     = "AUTH_MUTUAL_TLS"

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
    # * cd gcp/live/ENV
    # * rake sh"[sh -c \"cd /project/live/ENV/k8s/cluster && terragrunt state rm random_id.cluster_protector\"]"
    # * Destroy or re-create the cluster (cluster_protector will be re-created)
    # * See also: https://github.com/gpii-ops/gpii-infra/pull/199#issuecomment-463017515
    #
    # OR
    #
    # * Change the value below to 'false'
    # * Apply the change (to delete the cluster_protector resource)
    # * Destroy or re-create the cluster
    # * Change the value below back to 'true'
    # * Apply the change (to re-create the cluster_protector resource)
    prevent_destroy = true
  }
}
