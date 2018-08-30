terraform {
  backend "gcs" {}
}

variable "env" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "organization_domain" {}

variable "dns_zones" {
  type = "map"
}

variable "secret_couchdb_admin_username" {}
variable "secret_couchdb_admin_password" {}

variable "preferences_repository" {}
variable "preferences_checksum" {}

data "template_file" "preferences_values" {
  template = "${file("values.yaml")}"

  vars {
    env                    = "${var.env}"
    dns_name               = "${var.dns_zones["${var.env}-gcp-${replace(var.organization_domain, ".", "-")}"]}"
    preferences_repository = "${var.preferences_repository}"
    preferences_checksum   = "${var.preferences_checksum}"
    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
  }
}

module "gpii-preferences" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "preferences"
  release_namespace       = "gpii"
  release_values          = ""
  release_values_rendered = "${data.template_file.preferences_values.rendered}"

  chart_name = "${var.charts_dir}/gpii-preferences"
}
