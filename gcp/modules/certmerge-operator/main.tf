terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

module "certmerge-operator" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "certmerge-operator"
  release_namespace = "certmerge"

  chart_name = "${var.charts_dir}/certmerge-operator"
}
