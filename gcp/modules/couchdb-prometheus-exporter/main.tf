terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "couchdb_prometheus_exporter_repository" {}
variable "couchdb_prometheus_exporter_tag" {}
variable "prometheus_to_sd_repository" {}
variable "prometheus_to_sd_tag" {}

variable "replica_count" {
  default = "1"
}

# Secret variables
variable "secret_couchdb_admin_username" {}

variable "secret_couchdb_admin_password" {}

data "template_file" "couchdb_prometheus_exporter_values" {
  template = "${file("values.yaml")}"

  vars {
    couchdb_admin_username                 = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password                 = "${var.secret_couchdb_admin_password}"
    couchdb_prometheus_exporter_repository = "${var.couchdb_prometheus_exporter_repository}"
    couchdb_prometheus_exporter_tag        = "${var.couchdb_prometheus_exporter_tag}"
    prometheus_to_sd_repository            = "${var.prometheus_to_sd_repository}"
    prometheus_to_sd_tag                   = "${var.prometheus_to_sd_tag}"
    replica_count                          = "${var.replica_count}"
  }
}

module "couchdb-prometheus-exporter" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "couchdb-prometheus-exporter"
  release_namespace       = "gpii"
  release_values          = ""
  release_values_rendered = "${data.template_file.couchdb_prometheus_exporter_values.rendered}"

  chart_name = "${var.charts_dir}/couchdb-prometheus-exporter"
}
