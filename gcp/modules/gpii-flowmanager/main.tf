terraform {
  backend "gcs" {}
}

variable "values_dir" {}
variable "secrets_dir" {}
variable "charts_dir" {}

module "gpii-flowmanager" {
  source = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "flowmanager"
  release_namespace = "gpii"
  release_values    = "${var.values_dir}/gpii-flowmanager.yaml"

  chart_name = "${var.charts_dir}/gpii-flowmanager"
}
