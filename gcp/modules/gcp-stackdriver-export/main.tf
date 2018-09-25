terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}
variable "exports" {
  default = {}
}

module "gcp_stackdriver_export" {
  source             = "/exekube-modules/gcp-stackdriver-export"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"
  exports            = "${var.exports}"
}
