terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}

variable "waiting_period" {
  default = 60
}

module "gcp-api-mgmt" {
  source = "/exekube-modules/gcp-api-mgmt"

  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"
  waiting_period     = "${var.waiting_period}"
}
