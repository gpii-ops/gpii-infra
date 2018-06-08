terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

module "administration_tasks" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "administration-tasks"
  release_namespace = "gpii"

  chart_name = "administration-tasks/"
}
