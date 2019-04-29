terraform {
  backend "gcs" {}
}

variable "secrets_dir" {}
variable "charts_dir" {}
variable "certmerge_operator_repository" {}
variable "certmerge_operator_tag" {}

data "template_file" "certmerge_operator_values" {
  template = "${file("values.yaml")}"

  vars {
    certmerge_operator_repository = "${var.certmerge_operator_repository}"
    certmerge_operator_tag        = "${var.certmerge_operator_tag}"
  }
}

module "certmerge-operator" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "certmerge-operator"
  release_namespace       = "certmerge"
  release_values          = ""
  release_values_rendered = "${data.template_file.certmerge_operator_values.rendered}"

  chart_name = "${var.charts_dir}/certmerge-operator"
}
