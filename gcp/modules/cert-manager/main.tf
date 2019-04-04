terraform {
  backend "gcs" {}
}

variable "nonce" {}
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
    service_account = "${data.google_service_account.gke_cluster_pod_cert_manager.email}"
  }
}

module "cert-manager" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "cert-manager"
  release_namespace = "kube-system"

  chart_name              = "${var.charts_dir}/cert-manager"
  release_values          = ""
  release_values_rendered = "${data.template_file.release_values.rendered}"
}
