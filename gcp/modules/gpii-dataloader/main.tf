terraform {
  backend "gcs" {}
}

variable "values_dir" {}
variable "secrets_dir" {}
variable "charts_dir" {}

module "gpii-dataloader" {
  source = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "dataloader"
  release_namespace = "gpii"
  release_values    = "${var.values_dir}/gpii-dataloader.yaml"

  chart_name = "${var.charts_dir}/gpii-dataloader"
}
