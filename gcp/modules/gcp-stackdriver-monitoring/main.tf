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

resource "null_resource" "destroy_old_stackdriver_resources" {
  provisioner "local-exec" {
    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      RETRIES=10
      RETRY_COUNT=1
      while [ "$STACKDRIVER_DEADLINE_EXCEEDED" != "false" ]; do
        STACKDRIVER_DEADLINE_EXCEEDED="false"
        echo "[Try $RETRY_COUNT of $RETRIES] Deleting Stackdriver resources..."
        bundle exec ruby -e '
          require "/rakefiles/stackdriver.rb"
          destroy_resources({"alert_policies"=>[],
                            "notification_channels"=>[],
                            "log_based_metrics"=>[]})
        '
        STACKDRIVER_EXIT_STATUS="$?"
        if [ "$STACKDRIVER_EXIT_STATUS" == "120" ]; then
          STACKDRIVER_DEADLINE_EXCEEDED="true"
        elif [ "$STACKDRIVER_EXIT_STATUS" != "0" ]; then
          exit $STACKDRIVER_EXIT_STATUS
        fi
        if [ "$RETRY_COUNT" == "$RETRIES" ] && [ "$STACKDRIVER_DEADLINE_EXCEEDED" == "true" ]; then
          echo "Retry limit reached, giving up!"
          exit 1
        fi
        if [ "$STACKDRIVER_DEADLINE_EXCEEDED" == "true" ]; then
          sleep 10
        fi
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done
    EOF
  }
}

resource "null_resource" "wait_for_lbms" {
  depends_on = ["google_logging_metric.servicemanagement_modify", "google_logging_metric.dns_modify"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      MAX_RETRIES=60
      SLEEP_SEC=5
      for RESOURCE in ${google_logging_metric.servicemanagement_modify.name} ${google_logging_metric.dns_modify.name}; do
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
