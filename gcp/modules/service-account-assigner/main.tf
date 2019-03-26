terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "project_id" {}
variable "serviceaccount_key" {}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

data "template_file" "release_values" {
  template = "${file("${path.module}/templates/values.yaml.tpl")}"

  vars = {
    default_service_account = "${data.google_service_account.gke_cluster_pod_default.email}"
  }
}

module "service_account_assigner" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "service-account-assigner"
  release_namespace = "kube-system"

  release_values          = ""
  release_values_rendered = "${data.template_file.release_values.rendered}"

  chart_name = "${var.charts_dir}/service-account-assigner"
}
