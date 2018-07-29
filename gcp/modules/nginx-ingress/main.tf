terraform {
  backend "gcs" {}
}

variable "env" {}
variable "serviceaccount_key" {}
variable "project_id" {}
variable "secrets_dir" {}

variable "tfstate_bucket" {}
variable "tfstate_encryption_key" {}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config {
    credentials    = "${var.serviceaccount_key}"
    prefix         = "${var.env}/infra/network"
    bucket         = "${var.tfstate_bucket}"
    encryption_key = "${var.tfstate_encryption_key}"
  }
}

module "nginx-ingress" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "nginx-ingress"
  release_namespace = "gpii"

  chart_name = "../../../../../charts/nginx-ingress"

  load_balancer_ip = "${data.terraform_remote_state.network.static_ip_address}"
}
