terraform {
  backend "gcs" {}
}

variable "domain_name" {}
variable "project_id" {}
variable "nonce" {}
variable "serviceaccount_key" {}

module "stackdriver_resources" {
  source = "resources"

  project_id         = "${var.project_id}"
  domain_name        = "${var.domain_name}"
  serviceaccount_key = "${var.serviceaccount_key}"
}

resource "null_resource" "stackdriver_alerting" {
  depends_on = ["module.stackdriver_resources"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    interpreter = ["ruby"]
    command     = "${path.cwd}/resources_rendered/client.rb"
  }
}
