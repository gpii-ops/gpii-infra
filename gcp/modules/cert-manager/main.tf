terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

module "cert-manager" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "cert-manager"
  release_namespace = "kube-system"

  chart_name = "../../../../../charts/cert-manager"
}

resource "null_resource" "cert_manager_resources" {
  depends_on = ["module.cert-manager"]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/resources/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete --ignore-not-found -f ${path.module}/resources/"
  }
}
