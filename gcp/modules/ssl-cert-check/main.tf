terraform {
  backend "gcs" {}
}

variable "charts_dir" {}
variable "secrets_dir" {}

variable "domain_name" {}

variable "prometheus_to_sd_repository" {}
variable "prometheus_to_sd_tag" {}

variable "ssl_cert_check_repository" {}
variable "ssl_cert_check_tag" {}

data "template_file" "ssl_cert_check_values" {
  template = "${file("values.yaml")}"

  vars {
    domain_name                 = "${var.domain_name}"
    prometheus_to_sd_repository = "${var.prometheus_to_sd_repository}"
    prometheus_to_sd_tag        = "${var.prometheus_to_sd_tag}"
    ssl_cert_check_repository   = "${var.ssl_cert_check_repository}"
    ssl_cert_check_tag          = "${var.ssl_cert_check_tag}"
  }
}

module "ssl_cert_check" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "ssl-cert-check"
  release_namespace       = "kube-system"
  release_values          = ""
  release_values_rendered = "${data.template_file.ssl_cert_check_values.rendered}"

  chart_name   = "${var.charts_dir}/ssl-cert-check"
  force_update = true
}
