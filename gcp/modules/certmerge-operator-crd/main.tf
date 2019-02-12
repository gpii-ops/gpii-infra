terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

module "certmerge-operator-crd" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "certmerge-operator-crd"
  release_namespace = "certmerge"

  chart_name = "${var.charts_dir}/certmerge-operator-crd"
}
