terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "destination_bucket" {}
variable "project_id" {}
variable "replica_count" {}

# Terragrunt variables

data "template_file" "backup-exporter" {
  template = "${file("values.yaml")}"

  vars {
    service_account_json  = "${google_service_account_key.service_account_json.private_key}"
    service_account_name  = "${local.service_account_name}"
    destination_bucket    = "${var.destination_bucket}"
    replica_count         = "${var.replica_count}"
  }
}

resource "google_service_account_key" "service_account_json" {
  service_account_id = "${local.service_account_name}"
}

locals {
  service_account_name = "backup-exporter@${var.project_id}.iam.gserviceaccount.com"
}
module "backup-exporter" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "backup-exporter"
  release_namespace       = "backup-exporter"
  release_values          = ""
  release_values_rendered = "${data.template_file.backup-exporter.rendered}"

  chart_name = "${var.charts_dir}/backup-exporter"
}
