terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "destination_bucket" {}
variable "project_id" {}
variable "replica_count" {}
variable "schedule" {}

# Terragrunt variables

data "google_project" "project" {
  project_id = "${var.project_id}"
}

data "template_file" "backup-exporter" {
  template = "${file("values.yaml")}"

  vars {
    service_account_name = "${data.google_service_account.backup_exporter.email}"
    destination_bucket   = "${var.destination_bucket}"
    replica_count        = "${var.replica_count}"
    schedule             = "${var.schedule}"
  }
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

resource "google_storage_bucket" "backup_daisy_bkt" {
  project = "${data.google_project.project.project_id}"
  name    = "${data.google_project.project.name}-daisy-bkt"

  force_destroy = true
}
