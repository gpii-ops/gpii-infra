terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

module "administration_tasks" {
  source = "/exekube-modules/helm-template-release"
  ###tiller_namespace = "kube-system"
  ###client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name      = "administration-tasks"
  release_namespace = "gpii"

  chart_name    = "administration-tasks/"
}
