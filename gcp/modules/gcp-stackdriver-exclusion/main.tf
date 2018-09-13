terraform {
  backend "gcs" {}
}

variable "project_id" {}
variable "serviceaccount_key" {}
variable "exclusion_name" {}
variable "exclusion_description" {}
variable "exclusion_filter" {}

module "gcp_stackdriver_exclusion" {
  source                = "/exekube-modules/gcp-stackdriver-exclusion"
  project_id            = "${var.project_id}"
  serviceaccount_key    = "${var.serviceaccount_key}"
  exclusion_name        = "${var.exclusion_name}"
  exclusion_description = "${var.exclusion_description}"
  exclusion_filter      = "${var.exclusion_filter}"
}
