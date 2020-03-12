terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "kube_state_metrics_repository" {}
variable "kube_state_metrics_tag" {}
variable "prometheus_to_sd_repository" {}
variable "prometheus_to_sd_tag" {}

data "template_file" "kube_state_metrics_values" {
  template = "${file("values.yaml")}"

  vars {
    kube_state_metrics_repository = "${var.kube_state_metrics_repository}"
    kube_state_metrics_tag        = "${var.kube_state_metrics_tag}"
    prometheus_to_sd_repository   = "${var.prometheus_to_sd_repository}"
    prometheus_to_sd_tag          = "${var.prometheus_to_sd_tag}"
  }
}

module "kube-state-metrics" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "kube-state-metrics"
  release_namespace       = "kube-system"
  release_values          = ""
  release_values_rendered = "${data.template_file.kube_state_metrics_values.rendered}"

  chart_name = "${var.charts_dir}/kube-state-metrics"
}
