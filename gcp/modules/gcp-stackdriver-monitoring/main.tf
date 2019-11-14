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

variable "project_id" {}
variable "organization_id" {}
variable "notification_email" {}
variable "common_project_id" {}
variable "domain_name" {}
variable "serviceaccount_key" {}
variable "env" {}

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
