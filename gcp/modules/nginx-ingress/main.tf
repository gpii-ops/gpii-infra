terraform {
  backend "gcs" {}
}

variable "env" {}
variable "serviceaccount_key" {}
variable "project_id" {}

data "terraform_remote_state" "network" {
  backend = "gcs"
  config {
    credentials = "${var.serviceaccount_key}"
    bucket      = "${var.project_id}-tfstate"
    prefix      = "${var.env}/infra/network"
  }
}

module "nginx-ingress" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "nginx-ingress"
  release_namespace = "gpii"

  chart_name = "../../../../../charts/nginx-ingress"

  load_balancer_ip = "${data.terraform_remote_state.network.static_ip_address}"
}
