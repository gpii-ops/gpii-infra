terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}

module "couchdb" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "couchdb"
  release_namespace = "gpii"

  chart_name    = "couchdb/"
}
