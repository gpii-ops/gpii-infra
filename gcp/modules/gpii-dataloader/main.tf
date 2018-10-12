terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

variable "dataloader_repository" {}
variable "dataloader_checksum" {}

variable "secret_couchdb_admin_username" {}
variable "secret_couchdb_admin_password" {}

data "template_file" "dataloader_values" {
  template = "${file("values.yaml")}"

  vars {
    dataloader_repository = "${var.dataloader_repository}"

    # This is an ugly hack to stop TF/Helm dataloader errors and should be removed
    # in scope of https://github.com/gpii-ops/gpii-infra/pull/163
    # dataloader_checksum    = "${var.dataloader_checksum}"
    dataloader_checksum = "sha256:3876e3526b8b59f94aa25c8b6d1a3166df115d402b51176ef8bd91c899430369"

    couchdb_admin_username = "${var.secret_couchdb_admin_username}"
    couchdb_admin_password = "${var.secret_couchdb_admin_password}"
  }
}

module "gpii-dataloader" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "dataloader"
  release_namespace       = "gpii"
  release_values          = ""
  release_values_rendered = "${data.template_file.dataloader_values.rendered}"

  chart_name = "${var.charts_dir}/gpii-dataloader"
}
