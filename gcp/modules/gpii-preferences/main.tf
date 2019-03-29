terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "env" {}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "domain_name" {}

variable "preferences_repository" {}
variable "preferences_checksum" {}

# Terragrunt variables
variable "cert_issuer_name" {}

variable "replica_count" {}
variable "requests_cpu" {}
variable "requests_memory" {}
variable "limits_cpu" {}
variable "limits_memory" {}

# Secret variables
variable "secret_couchdb_admin_username" {}

variable "secret_couchdb_admin_password" {}

data "template_file" "preferences_values" {
  template = "${file("${path.module}/templates/values.yaml.tpl")}"
  vars {
    domain_name            = "${var.domain_name}"
    preferences_repository = "${var.preferences_repository}"
    preferences_checksum   = "${var.preferences_checksum}"
    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
    replica_count          = "${var.replica_count}"
    requests_cpu           = "${var.requests_cpu}"
    requests_memory        = "${var.requests_memory}"
    limits_cpu             = "${var.limits_cpu}"
    limits_memory          = "${var.limits_memory}"
    project_id             = "${var.project_id}"
    acme_server            = "${var.env == "prd" || var.env == "stg" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"}"
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
