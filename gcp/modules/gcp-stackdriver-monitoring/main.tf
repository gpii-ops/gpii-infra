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

# Cloud Resource Manager system account to exclude in IAM modification LBM
variable "crm_sa" {
  default = "one-platform-tenant-manager@system.gserviceaccount.com"
}

variable "nonce" {}
variable "project_id" {}
variable "organization_id" {}
variable "notification_email" {}
variable "common_project_id" {}
variable "domain_name" {}
variable "serviceaccount_key" {}
variable "env" {}

variable "use_auth_user_email" {
  default = false
}

variable "auth_user_email" {}
variable "secret_slack_auth_token" {}

resource "null_resource" "wait_for_lbms" {
  depends_on = ["google_logging_metric.servicemanagement_modify", "google_logging_metric.dns_modify"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      MAX_RETRIES=60
      SLEEP_SEC=5
      for RESOURCE in ${google_logging_metric.servicemanagement_modify.name} \
                      ${google_logging_metric.dns_modify.name} \
                      ${google_logging_metric.backup_exporter_error.name} \
                      ${google_logging_metric.compute_instances_insert.name} \
                      ${google_logging_metric.iam_modify.name} \
                      ${google_logging_metric.backup_exporter_snapshot_created.name} \
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
