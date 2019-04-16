terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "project_id" {}
variable "serviceaccount_key" {}
variable "k8s_snapshots_repository" {}
variable "k8s_snapshots_tag" {}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

data "template_file" "release_values" {
  template = "${file("${path.module}/templates/values.yaml.tpl")}"

  vars = {
    service_account          = "${data.google_service_account.gke_cluster_pod_k8s_snapshots.email}"
    k8s_snapshots_repository = "${var.k8s_snapshots_repository}"
    k8s_snapshots_tag        = "${var.k8s_snapshots_tag}"
  }
}

module "k8s-snapshots" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "k8s-snapshots"
  release_namespace = "kube-system"

  release_values          = ""
  release_values_rendered = "${data.template_file.release_values.rendered}"

  chart_name = "${var.charts_dir}/k8s-snapshots"
}
