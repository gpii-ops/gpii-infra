terraform {
  backend "gcs" {}
}

variable "values_dir" {}

module "couchdb" {

  source = "/exekube-modules/helm-template-release"

  release_name      = "couchdb"
  release_namespace = "gpii"
  release_values    = "${var.values_dir}/couchdb.yaml"

  chart_name    = "chart/"
}
