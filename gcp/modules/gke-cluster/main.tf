terraform {
  backend "gcs" {}
}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

provider "google-beta" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

variable "project_id" {}
variable "serviceaccount_key" {}
variable "env" {}

# Terragrunt variables
variable "node_type" {}

variable "node_count" {
  default = 1
}

variable "expected_gke_version_prefix" {
  default = "1.12"
}

variable "infra_region" {}

variable "prevent_destroy_cluster" {
  default = false
}

variable "binary_authorization_evaluation_mode" {
  default = "ALWAYS_ALLOW"
}

variable "binary_authorization_enforcement_mode" {
  default = "ENFORCED_BLOCK_AND_AUDIT_LOG"
}

variable "binary_authorization_admission_whitelist_patterns" {
  # Allow images from our GCR.
  default = ["gcr.io/gpii-common-prd/*"]
}

data "google_service_account" "gke_cluster_node" {
  account_id = "gke-cluster-node"
  project    = "${var.project_id}"
}

data "google_container_engine_versions" "this" {
  provider = "google-beta"
  project  = "${var.project_id}"
  region   = "${var.infra_region}"
}

data "external" "gke_version_assert" {
  program = [
    "bash",
    "-c",
    <<EOF
      if [[ '${data.google_container_engine_versions.this.default_cluster_version}' == ${var.expected_gke_version_prefix}* ]]; then
        echo '{"version": "${data.google_container_engine_versions.this.default_cluster_version}"}'
      else
        echo 'Default GKE version is ${data.google_container_engine_versions.this.default_cluster_version}, this would mean minor version upgrade!' >&2
        false
      fi
EOF
    ,
  ]
}

module "gke_cluster" {
  source             = "/exekube-modules/gke-cluster"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"

  kubernetes_version = "${data.external.gke_version_assert.result.version}"

  region = "${var.infra_region}"

  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"

  # Istio config
  istio_disabled = false
  istio_auth     = "AUTH_MUTUAL_TLS"

  dashboard_disabled           = true
  http_load_balancing_disabled = true

  # empty password and username disables legacy basic authentication
  master_auth_username = ""
  master_auth_password = ""

  issue_client_certificate = false

  update_timeout = "30m"

  primary_pool_min_node_count     = "${var.node_count}"
  primary_pool_max_node_count     = "${var.node_count}"
  primary_pool_initial_node_count = "${var.node_count}"
  primary_pool_machine_type       = "${var.node_type}"
  primary_pool_oauth_scopes       = ["cloud-platform"]
  primary_pool_service_account    = "${data.google_service_account.gke_cluster_node.email}"

  enable_binary_authorization                       = "true"
  binary_authorization_evaluation_mode              = "${var.binary_authorization_evaluation_mode}"
  binary_authorization_enforcement_mode             = "${var.binary_authorization_enforcement_mode}"
  binary_authorization_admission_whitelist_patterns = "${var.binary_authorization_admission_whitelist_patterns}"
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
