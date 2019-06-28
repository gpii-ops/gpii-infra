terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "cloud_sdk_repository" {}
variable "cloud_sdk_tag" {}
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
    cloud_sdk_repository      = "${var.cloud_sdk_repository}"
    cloud_sdk_tag             = "${var.cloud_sdk_tag}"
    service_account_name      = "${data.google_service_account.gke_cluster_pod_backup_exporter.email}"
    destination_bucket        = "${var.destination_bucket}"
    local_intermediate_bucket = "${google_storage_bucket.backup_daisy_bkt.name}"
    replica_count             = "${var.replica_count}"
    log_bucket                = "gs://${google_storage_bucket.backup_daisy_bkt.name}/logs"
    schedule                  = "${var.schedule}"
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
