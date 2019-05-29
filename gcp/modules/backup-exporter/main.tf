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
    service_account_name = "${data.google_service_account.gke_cluster_pod_backup_exporter.email}"
    destination_bucket   = "${var.destination_bucket}"
    replica_count        = "${var.replica_count}"
    log_bucket           = "gs://${google_storage_bucket.backup_daisy_bkt.name}/logs"
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

# The google_loggin_metric does not support counter metrics yet:
# https://github.com/terraform-providers/terraform-provider-google/issues/3698
# We will able to use this resource once it is fixed at Terraform
#
#resource "google_logging_metric" "logging_metric" {
#  name   = "backup-exporter.snapshot_created"
#  filter = "resource.type=\"k8s_container\" resource.labels.cluster_name=\"k8s-cluster\" resource.labels.namespace_name=\"backup-exporter\" resource.labels.container_name=\"backup-container\" textPayload=\"[Daisy] All workflows completed successfully.\n\""
#
#  project = "${var.project_id}"
#
#  metric_descriptor {
#    
#    labels {
#      key         = "success"
#      value_type  = "STRING"
#      description = "Last successfull message from the process"
#    }
#  }
#
#  label_extractors = {
#    "success" = "EXTRACT(textPayload)"
#  }
#}

