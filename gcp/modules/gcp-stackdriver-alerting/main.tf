terraform {
  backend "gcs" {}
}

variable "env" {}
variable "nonce" {}
variable "domain_name" {}
variable "project_id" {}
variable "serviceaccount_key" {}

resource "template_dir" "resources" {
  source_dir      = "${path.cwd}/resources"
  destination_dir = "${path.cwd}/resources_rendered"

  vars {
    project_id  = "${var.project_id}"
    domain_name = "${var.domain_name}"
    env         = "${var.env}"
  }
}

resource "null_resource" "apply_stackdriver_alerting" {
  depends_on = ["template_dir.resources"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      # export STACKDRIVER_DEBUG=1
      ruby -e '
        require "${path.module}/client.rb"
        resources = read_resources
        processed_notification_channels = process_notification_channels(resources["notification_channels"])
        process_uptime_checks(resources["uptime_checks"])
        process_alert_policies(resources["alert_policies"], processed_notification_channels)
      '
    EOF
  }
}

resource "null_resource" "destroy_stackdriver_alerting" {
  depends_on = ["template_dir.resources"]

  provisioner "local-exec" {
    when    = "destroy"
    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      ruby -e '
        require "${path.module}/client.rb"
        process_alert_policies
        process_uptime_checks
        process_notification_channels
      '
    EOF
  }
}
