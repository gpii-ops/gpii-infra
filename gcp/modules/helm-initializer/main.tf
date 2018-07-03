terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

variable tiller_namespace {
  default = "kube-system"
}

# Install Tiller in kube-system namespace with cluster-admin access to all namespaces
module "system_tiller" {
  source = "/exekube-modules/helm-initializer"

  secrets_dir      = "${var.secrets_dir}"
  tiller_namespace = "${var.tiller_namespace}"
}

resource "null_resource" "wait_for_tiller" {
  depends_on = ["module.system_tiller"]

  provisioner "local-exec" {
    command = "sleep 60"
  }
}
