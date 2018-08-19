terraform {
  backend "gcs" {}
}

variable "env" {}
variable "secrets_dir" {}
variable "charts_dir" {}

variable "dns_zones" {
  type = "map"
}

data "template_file" "locust_values" {
  template = "${file("values.yaml")}"

  vars {
    locust_workers = "${var.env == "dev" ? "3" : "6"}"
    target_host    = "${var.env == "dev" ? "http" : "https"}://preferences.${
      var.locust_target_host == "" ? substr(
        var.dns_zones["${var.env}-gcp-gpii-net"], 0,
        length(var.dns_zones["${var.env}-gcp-gpii-net"]) - 1)
        : var.locust_target_host
    }"
  }
}

module "locust" {
  source           = "/exekube-modules/helm-release"
  tiller_namespace = "kube-system"
  client_auth      = "${var.secrets_dir}/kube-system/helm-tls"

  release_name            = "locust"
  release_namespace       = "locust"
  release_values          = ""
  release_values_rendered = "${data.template_file.locust_values.rendered}"

  chart_name = "${var.charts_dir}/locust"
}
