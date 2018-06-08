terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

variable "load_balancer_ip" {}

module "nginx_ingress" {
  source            = "/exekube-modules/helm-release"
  tiller_namespace  = "kube-system"
  client_auth       = "${var.secrets_dir}/kube-system/helm-tls"
  release_name      = "nginx-ingress"
  release_namespace = "kube-system"

  chart_repo    = "stable"
  chart_name    = "nginx-ingress"
  chart_version = "0.13.2"

  load_balancer_ip = "${var.load_balancer_ip}"
}
