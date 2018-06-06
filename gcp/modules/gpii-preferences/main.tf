terraform {
  backend "gcs" {}
}

variable "values_dir" {}

module "gpii-preferences" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "preferences"
  release_namespace = "gpii"
  release_values    = "${var.values_dir}/gpii-preferences.yaml"

  chart_name    = "chart/"
}
