terraform {
  backend "gcs" {}
}

variable "env" {}
variable "project_id" {}
variable "serviceaccount_key" {}
variable "secrets_dir" {}
variable "charts_dir" {}
variable "nonce" {}
variable "locust_repository" {}
variable "locust_tag" {}

resource "null_resource" "locust_copy_tasks" {
  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${var.charts_dir}/locust/tasks
      for FILE in tasks/*.py; do
        echo "Copying $FILE..."
        cp -f $PWD/$FILE ${var.charts_dir}/locust/$FILE
      done
    EOF
  }
}

data "template_file" "locust_values" {
  template = "${file("values.yaml")}"

  vars {
    locust_repository = "${var.locust_repository}"
    locust_tag        = "${var.locust_tag}"
    locust_workers    = "${var.locust_workers}"
    target_host       = "${var.locust_target_host}"
    locust_script     = "${var.locust_script}"
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

resource "null_resource" "locust_cleanup" {
  depends_on = ["module.locust"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "Removing tasks..."
      rm -rf ${var.charts_dir}/locust/tasks/*.py
    EOF
  }
}
