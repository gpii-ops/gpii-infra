terraform {
  backend "gcs" {}
}

variable "env" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "nonce" {}

variable "dns_zones" {
  type = "map"
}

resource "null_resource" "locust_link_tasks" {
  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      rm -rf ${var.charts_dir}/locust/tasks
      mkdir -p ${var.charts_dir}/locust/tasks
      for FILE in tasks/*.py; do
        echo "Creating link for $FILE"
        ln -sf -T $PWD/$FILE ${var.charts_dir}/locust/$FILE
      done
    EOF
  }
}

data "template_file" "locust_values" {
  template = "${file("values.yaml")}"

  vars {
    locust_workers = "${var.locust_workers}"
    target_host    = "${var.locust_target_host == "" ?
      "${var.env == "dev" ? "http" : "https"}://preferences.${
        substr(var.dns_zones["${var.env}-gcp-gpii-net"], 0,
        length(var.dns_zones["${var.env}-gcp-gpii-net"]) - 1)}"
        : var.locust_target_host
    }"
    locust_script  = "${var.locust_script}"
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
