terraform {
  backend "gcs" {}
}

variable "namespace_name" {}

module "k8s_namespace" {
  source = "/exekube-modules/k8s-namespace"

  namespace_name      = "${var.namespace_name}"
}
