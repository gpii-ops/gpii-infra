terraform {
  backend "gcs" {}
}

variable "env" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "domain_name" {}

variable "secret_couchdb_admin_username" {}
variable "secret_couchdb_admin_password" {}

variable "flowmanager_repository" {}
variable "flowmanager_checksum" {}

data "template_file" "flowmanager_values" {
  template = "${file("values.yaml")}"

  vars {
    env                    = "${var.env}"
    domain_name            = "${var.domain_name}"
    flowmanager_repository = "${var.flowmanager_repository}"
    flowmanager_checksum   = "${var.flowmanager_checksum}"
    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
  }
}

module "gpii-flowmanager" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "flowmanager"
  release_namespace       = "gpii"
  release_values          = ""
  release_values_rendered = "${data.template_file.flowmanager_values.rendered}"

  chart_name = "${var.charts_dir}/gpii-flowmanager"
}


resource "null_resource" "flowmanager_resources" {
  depends_on = ["module.gpii-flowmanager"]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/resources/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete --ignore-not-found -f ${path.module}/resources/"
  }
}
