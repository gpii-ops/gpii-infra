terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

variable tiller_namespace {
  default = "kube-system"
}

# Generate TLS assets into same dir that helm-initializer configured to use
module "helm_tls" {
  source = "/exekube-modules/helm-tls"

  secrets_dir      = "${var.secrets_dir}"
  tiller_namespace = "${var.tiller_namespace}"
}
