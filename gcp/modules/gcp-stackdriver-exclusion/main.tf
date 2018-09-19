terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}
variable "exclusions" {
  default = {}
}

module "gcp_stackdriver_exclusion" {
  source             = "/exekube-modules/gcp-stackdriver-exclusion"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"
  exclusions         = "${var.exclusions}"
}
