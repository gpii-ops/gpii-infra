terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "kiali_repository" {}
variable "kiali_tag" {}

module "prometheus" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "prometheus"
  release_namespace = "istio-system"
  release_values    = ""

  chart_name = "${var.charts_dir}/istio-prometheus"
}

data "template_file" "release_values" {
  template = "${file("${path.module}/templates/values.yaml.tpl")}"

  vars = {
    kiali_repository = "${var.kiali_repository}"
    kiali_tag        = "${var.kiali_tag}"
  }
}

module "kiali" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "kiali"
  release_namespace       = "istio-system"
  release_values          = ""
  release_values_rendered = "${data.template_file.release_values.rendered}"

  chart_name = "${var.charts_dir}/istio-kiali"
}
