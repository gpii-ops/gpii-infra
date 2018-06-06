terraform {
  backend "gcs" {}
}

variable "values_dir" {}

module "gpii-dataloader" {
  source = "/exekube-modules/helm-template-release"

  release_name      = "dataloader"
  release_namespace = "gpii"
  release_values    = "${var.values_dir}/gpii-dataloader.yaml"

  chart_name    = "chart/"
}
