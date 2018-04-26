terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

# Install Tiller in kube-system namespace with cluster-admin access to all namespaces
module "system_tiller" {
  source = "/exekube-modules/helm-initializer"

  secrets_dir      = "${var.secrets_dir}"
  tiller_namespace = "kube-system"
}
