terraform {
  backend "gcs" {}
}

variable "nonce" {}
variable "domain_name" {}
variable "project_id" {}
variable "serviceaccount_key" {}

# Terragrunt variable
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
      export STACKDRIVER_DEBUG=${var.stackdriver_debug}
      ruby -e '
        require "${path.module}/client.rb"
        apply_resources
      '
    EOF
  }
}

resource "null_resource" "destroy_stackdriver_alerting" {
  depends_on = ["template_dir.resources"]

  provisioner "local-exec" {
    when = "destroy"

    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      ruby -e '
        require "${path.module}/client.rb"
        destroy_resources
      '
    EOF
  }
}
