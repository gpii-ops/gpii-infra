terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

# Terragrunt variables

# Secret variables

variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "service_account_name" {
  default = "backup-exporter@${var.project_id}.iam.gserviceaccount.com"
}

data "template_file" "backup-exporter" {
  template = "${file("values.yaml")}"

  vars {
    aws_access_key_id     = "${var.aws_access_key_id}"
    aws_secret_access_key = "${var.aws_secret_access_key}"
    service_account_json  = "${google_service_account_key.service_account_json.private_key}"
    service_account_name  = "${var.service_account_name}"
    s3_bucket             = "s3://${var.project_id}"
  }
}

resource "google_service_account_key" "service_account_json" {
  service_account_id = "${var.service_account_name}"
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
