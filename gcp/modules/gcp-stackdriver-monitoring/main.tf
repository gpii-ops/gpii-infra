terraform {
  backend "gcs" {}
}

variable "env" {}
variable "nonce" {}
variable "domain_name" {}
variable "project_id" {}
variable "serviceaccount_key" {}
variable "auth_user_email" {}

# Terragrunt variables

variable "notification_email" {}
variable "ssl_enabled_uptime_checks" {}

# Enables debug mode when TF_VAR_stackdriver_debug is not empty

variable "stackdriver_debug" {
  default = ""
}

resource "template_dir" "resources" {
  source_dir      = "${path.cwd}/resources"
  destination_dir = "${path.cwd}/resources_rendered"

  vars {
    project_id                = "${var.project_id}"
    domain_name               = "${var.domain_name}"
    ssl_enabled_uptime_checks = "${var.ssl_enabled_uptime_checks}"
    notification_email        = "${(var.env == "dev" && var.auth_user_email != "") ? var.auth_user_email : var.notification_email}"
  }
}

resource "null_resource" "apply_stackdriver_monitoring" {
  depends_on = ["template_dir.resources"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      export STACKDRIVER_DEBUG=${var.stackdriver_debug}

      RETRIES=10
      RETRY_COUNT=1
      while [ "$STACKDRIVER_DID_NOT_FAIL" != "true" ]; do
        STACKDRIVER_DID_NOT_FAIL="true"
        echo "[Try $RETRY_COUNT of $RETRIES] Applying Stackdriver resources..."
        ruby -e '
          require "/rakefiles/stackdriver.rb"
          resources = read_resources("${path.module}/resources_rendered")
          apply_resources(resources)
        '
        if [ "$?" != "0" ]; then
          STACKDRIVER_DID_NOT_FAIL="false"
        fi

        if [ "$RETRY_COUNT" == "$RETRIES" ]; then
          echo "Retry limit reached, giving up!"
          exit 1
        fi
        if [ "$STACKDRIVER_DID_NOT_FAIL" == "false" ]; then
          sleep 10
        fi
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done
    EOF
  }
}

resource "null_resource" "destroy_stackdriver_monitoring" {
  depends_on = ["template_dir.resources"]

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}

      RETRIES=5
      RETRY_COUNT=1
      while [ "$STACKDRIVER_DID_NOT_FAIL" != "true" ]; do
        STACKDRIVER_DID_NOT_FAIL="true"
        echo "[Try $RETRY_COUNT of $RETRIES] Destroying Stackdriver resources..."
        ruby -e '
          require "/rakefiles/stackdriver.rb"
          destroy_resources(["uptime_checks","alert_policies","notification_channels"])
        '
        if [ "$?" != "0" ]; then
          STACKDRIVER_DID_NOT_FAIL="false"
        fi

        if [ "$RETRY_COUNT" == "$RETRIES" ]; then
          echo "Retry limit reached, giving up!"
          exit 1
        fi
        if [ "$STACKDRIVER_DID_NOT_FAIL" == "false" ]; then
          sleep 10
        fi
        RETRY_COUNT=$(($RETRY_COUNT+1))
      done
    EOF
  }
}
