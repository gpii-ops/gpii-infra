terraform {
  backend "gcs" {}
}

variable "nonce" {}
variable "project_id" {}
variable "serviceaccount_key" {}

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
      while [ "$STACKDRIVER_DID_NOT_FAIL" != "true" ]; do
        STACKDRIVER_DID_NOT_FAIL="true"
        echo "[Try $RETRY_COUNT of $RETRIES] Applying Stackdriver resources..."
        ruby -e '
          require "/rakefiles/stackdriver.rb"
          resources = read_resources("${path.module}/resources")
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

resource "null_resource" "destroy_stackdriver_lbm" {
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
          destroy_resources({"log_based_metrics"=>[]})
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
