terraform {
  backend "gcs" {}
}

provider "google-beta" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

# Cloud Resource Manager system account to exclude in IAM modification LBM
variable "crm_sa" {
  default = "one-platform-tenant-manager@system.gserviceaccount.com"
}

variable "organization_id" {}

variable "common_project_id" {}

variable "env" {}
variable "serviceaccount_key" {}
variable "project_id" {}
variable "auth_user_email" {}
variable "nonce" {}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "domain_name" {}

variable "flowmanager_repository" {}
variable "flowmanager_checksum" {}

variable "replica_count" {}
variable "requests_cpu" {}
variable "requests_memory" {}
variable "limits_cpu" {}
variable "limits_memory" {}

# Secret variables
variable "secret_couchdb_admin_username" {}

variable "secret_couchdb_admin_password" {}

variable "key_tfstate_encryption_key" {}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

locals {
  user_email = "${var.auth_user_email != "" ? var.auth_user_email : "dev-null@raisingthefloor.org"}"
  acme_email = "${var.env == "prd" || var.env == "stg" ? "ops@raisingthefloor.org" : local.user_email}"
}

data "template_file" "flowmanager_values" {
  template = "${file("${path.module}/templates/values.yaml.tpl")}"

  vars {
    domain_name            = "${var.domain_name}"
    flowmanager_repository = "${var.flowmanager_repository}"
    flowmanager_checksum   = "${var.flowmanager_checksum}"
    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
    replica_count          = "${var.replica_count}"
    requests_cpu           = "${var.requests_cpu}"
    requests_memory        = "${var.requests_memory}"
    limits_cpu             = "${var.limits_cpu}"
    limits_memory          = "${var.limits_memory}"
    project_id             = "${var.project_id}"
    acme_server            = "${var.env == "prd" || var.env == "stg" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"}"
    acme_email             = "${local.acme_email}"
  }
}

module "gpii-flowmanager" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "flowmanager"
  release_namespace       = "gpii"
  release_values          = ""
  release_values_rendered = "${data.template_file.flowmanager_values.rendered}"

  chart_name = "${var.charts_dir}/gpii-flowmanager"
}

data "terraform_remote_state" "alert_notification_channel" {
  backend = "gcs"

  config {
    credentials    = "${var.serviceaccount_key}"
    bucket         = "${var.project_id}-tfstate"
    prefix         = "${var.env}/k8s/stackdriver/monitoring"
    encryption_key = "${var.key_tfstate_encryption_key}"
  }
}

# Wait for some lbm that seem to take more time than expected to be ready for the alerts policies
resource "null_resource" "wait_for_lbms" {
  depends_on = ["module.gpii-flowmanager"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      MAX_RETRIES=60
      SLEEP_SEC=5
      for RESOURCE in ${google_logging_metric.servicemanagement_modify.name} \
                      ${google_logging_metric.disks_createsnapshot.name} \
                      ${google_logging_metric.dns_modify.name} \
                      ${google_logging_metric.compute_instances_insert.name} \
                      ${google_logging_metric.iam_modify.name} \
                      ${google_logging_metric.stackdriver_alertpolicy_modify.name}; do
        ALERT_READY=false
        COUNT=1
        while [ "$ALERT_READY" != 'true' ] && [ "$COUNT" -le "$MAX_RETRIES" ]; do
          echo "Waiting for log based metric $RESOURCE to be ready ($COUNT/$MAX_RETRIES)"
          gcloud logging metrics describe $RESOURCE > /dev/null
          [ "$?" -eq 0 ] && ALERT_READY=true
          # Sleep only if we're not ready
          [ "$ALERT_READY" != 'true' ] && sleep "$SLEEP_SEC"
          COUNT=$((COUNT+1))
        done
      done
    EOF
  }
}
