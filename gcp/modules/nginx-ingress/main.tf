terraform {
  backend "gcs" {}
}

variable "env" {}
variable "serviceaccount_key" {}
variable "project_id" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "nginx_ingress_repository" {}
variable "nginx_ingress_tag" {}
variable "prometheus_to_sd_repository" {}
variable "prometheus_to_sd_tag" {}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config {
    credentials = "${var.serviceaccount_key}"
    bucket      = "${var.project_id}-tfstate"
    prefix      = "${var.env}/infra/network"

    # TODO: Next line should be removed once Terraform issue with GCS backend encryption is fixed
    # https://issues.gpii.net/browse/GPII-3329
    encryption_key = "/dev/null"
  }
}

data "template_file" "nginx_ingress_values" {
  template = "${file("values.yaml")}"

  vars {
    nginx_ingress_repository    = "${var.nginx_ingress_repository}"
    nginx_ingress_tag           = "${var.nginx_ingress_tag}"
    prometheus_to_sd_repository = "${var.prometheus_to_sd_repository}"
    prometheus_to_sd_tag        = "${var.prometheus_to_sd_tag}"
    load_balancer_ip            = "${data.terraform_remote_state.network.static_ip_address}"
  }
}

module "nginx-ingress" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "nginx-ingress"
  release_namespace       = "gpii"
  release_values          = ""
  release_values_rendered = "${data.template_file.nginx_ingress_values.rendered}"

  chart_name = "${var.charts_dir}/nginx-ingress"

  load_balancer_ip = "${data.template_file.nginx_ingress_values.rendered.load_balancer_ip}"
}
