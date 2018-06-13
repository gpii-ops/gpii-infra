terraform {
  backend "gcs" {}
}

variable "load_balancer_ip" {}

module "nginx-ingress" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "nginx-ingress"
  release_namespace = "gpii"

  chart_name = "../../../../../charts/nginx-ingress"

  load_balancer_ip = "${var.load_balancer_ip}"
}
