terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

variable "flushtokens_repository" {}
variable "flushtokens_checksum" {}

variable "secret_couchdb_admin_username" {}
variable "secret_couchdb_admin_password" {}

data "template_file" "flushtokens_values" {
  template = "${file("values.yaml")}"

  vars {
    flushtokens_repository = "${var.flushtokens_repository}"
    flushtokens_checksum   = "${var.flushtokens_checksum}"

    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
  }
}

module "gpii-flushtokens" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "flushtokens"
  release_namespace       = "gpii"
  release_values          = ""
  release_values_rendered = "${data.template_file.flushtokens_values.rendered}"

  chart_name   = "${var.charts_dir}/gpii-flushtokens"
  force_update = true
}
