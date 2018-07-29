terraform {
  backend "gcs" {}
}

variable "env" {}
variable "serviceaccount_key" {}
variable "project_id" {}
variable "secrets_dir" {}

variable "key_tfstate_encryption_key" {}

data "terraform_remote_state" "network" {
  backend = "gcs"

  config {
    credentials    = "${var.serviceaccount_key}"
    prefix         = "${var.env}/infra/network"
    bucket         = "${var.project_id}-tfstate"
    encryption_key = "${var.key_tfstate_encryption_key}"
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
