terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

module "k8s-snapshots" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "k8s-snapshots"
  release_namespace = "kube-system"

  chart_name = "${var.charts_dir}/k8s-snapshots"
}
