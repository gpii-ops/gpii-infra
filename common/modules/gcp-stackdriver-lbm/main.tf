terraform {
  backend "gcs" {}
}

variable "nonce" {}
variable "project_id" {}
variable "organization_id" {}
variable "serviceaccount_key" {}
variable "common_project_id" {}

resource "template_dir" "resources" {
  source_dir      = "${path.cwd}/resources"
  destination_dir = "${path.cwd}/resources_rendered"

  vars {
    organization_id = "${var.organization_id}"
    common_sa       = "projectowner@${var.common_project_id}.iam.gserviceaccount.com"
    project_id      = "${var.project_id}"
  }
}

# Enables debug mode when TF_VAR_stackdriver_debug is not empty

variable "stackdriver_debug" {
  default = ""
}

resource "null_resource" "apply_stackdriver_lbm" {
  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      export STACKDRIVER_DEBUG=${var.stackdriver_debug}

      RETRIES=5
      RETRY_COUNT=1
      while [ "$STACKDRIVER_DEADLINE_EXCEEDED" != "false" ]; do
        STACKDRIVER_DEADLINE_EXCEEDED="false"
        echo "[Try $RETRY_COUNT of $RETRIES] Applying Stackdriver resources..."
        bundle exec ruby -e '
          require "/rakefiles/stackdriver.rb"
          resources = read_resources("${path.module}/resources_rendered")
          apply_resources(resources)
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

resource "null_resource" "destroy_stackdriver_lbm" {
  provisioner "local-exec" {
    when = "destroy"

    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}

      RETRIES=5
      RETRY_COUNT=1
      while [ "$STACKDRIVER_DEADLINE_EXCEEDED" != "false" ]; do
        STACKDRIVER_DEADLINE_EXCEEDED="false"
        echo "[Try $RETRY_COUNT of $RETRIES] Destroying Stackdriver resources..."
        bundle exec ruby -e '
          require "/rakefiles/stackdriver.rb"
          destroy_resources({"log_based_metrics"=>[]})
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
