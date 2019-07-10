terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

module "certmerge-operator-crd" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name = "certmerge-operator-crd"

  # This is to fix issue with K8s garbage collector (GPII-3903), which does not support
  # cross-namespace garbage collection correctly
  release_namespace = "istio-system"

  chart_name = "${var.charts_dir}/certmerge-operator-crd"
}
