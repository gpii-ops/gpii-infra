terraform {
  backend "gcs" {}
}

variable "nonce" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "project_id" {}
variable "serviceaccount_key" {}
variable "cert_manager_repository" {}
variable "cert_manager_tag" {}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

data "template_file" "cert_manager_values" {
  template = "${file("values.yaml")}"

  vars {
    cert_manager_repository = "${var.cert_manager_repository}"
    cert_manager_tag        = "${var.cert_manager_tag}"
  }
}

module "cert-manager" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "cert-manager"
  release_namespace       = "kube-system"
  release_values          = ""
  release_values_rendered = "${data.template_file.cert_manager_values.rendered}"

  chart_name = "${var.charts_dir}/cert-manager"
}

resource "null_resource" "cert_manager_resources" {
  depends_on = ["module.cert-manager"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/resources/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete --ignore-not-found -f ${path.module}/resources/ || true"
  }
}
