terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

module "prometheus" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "prometheus"
  release_namespace = "istio-system"
  release_values    = ""

  chart_name = "${var.charts_dir}/istio-prometheus"
}

module "kiali" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "kiali"
  release_namespace = "istio-system"
  release_values    = ""

  chart_name = "${var.charts_dir}/istio-kiali"
}
