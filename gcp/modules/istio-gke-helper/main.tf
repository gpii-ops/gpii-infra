# This functionality cannot co-exist in istio module due to Terraform's
# inability to handle dynamic provider configuration for import command (even
# though the provider is not used for the actual resource import, helm_release
# & helm provider use data source dependent config). See
# hashicorp/terraform#17847 for details.

terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

module "istio-gke-helper" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "istio-gke-helper"
  release_namespace = "istio-system"
  release_values    = ""

  chart_name = "${var.charts_dir}/istio-gke-helper"
}

module "istio-gateways" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "istio-gateways"
  release_namespace = "istio-system"
  release_values    = ""

  chart_name = "${var.charts_dir}/istio-gateways"
}
