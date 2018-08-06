terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}

module "cert-manager" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "cert-manager"
  release_namespace = "kube-system"

  chart_name = "${var.charts_dir}/cert-manager"
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
