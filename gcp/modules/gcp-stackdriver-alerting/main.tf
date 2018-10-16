terraform {
  backend "gcs" {}
}

variable "domain_name" {}
variable "project_id" {}
variable "nonce" {}
variable "serviceaccount_key" {}

resource "template_dir" "resources" {
  source_dir      = "${path.cwd}/resources"
  destination_dir = "${path.cwd}/resources_rendered"

  vars {
    project_id  = "${var.project_id}"
    domain_name = "${var.domain_name}"
  }
}

resource "null_resource" "stackdriver_alerting" {
  depends_on = ["template_dir.resources"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      ruby ${path.module}/client.rb
    EOF
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = <<EOF
      export PROJECT_ID=${var.project_id}
      export GOOGLE_CLOUD_KEYFILE=${var.serviceaccount_key}
      export DESTROY=1
      ruby ${path.module}/client.rb
    EOF
  }
}
