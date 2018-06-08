terraform {
  backend "gcs" {}
}

variable "values_dir" {}

module "gpii-flowmanager" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "flowmanager"
  release_namespace = "gpii"
  release_values    = "${var.values_dir}/gpii-flowmanager.yaml"

  chart_name = "chart/"
}
