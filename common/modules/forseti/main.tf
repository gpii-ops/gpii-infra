terraform {
  backend "gcs" {}
}

variable "serviceaccount_key" {}
variable "project_id" {}
variable "infra_region" {}
variable "auth_user_email" {}
variable "organization_id" {}
variable "domain_name" {}
variable "server_grpc_allow_ranges" {}
variable "cscc_source_id" {}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "${var.infra_region}"
}

module "forseti" {
  source  = "terraform-google-modules/forseti/google"
  version = "~> 1.4.1"

  gsuite_admin_email = "${var.auth_user_email}"
  domain             = "${var.domain_name}"
  project_id         = "${var.project_id}"
  org_id             = "${var.organization_id}"
  network            = "forseti"
  subnetwork         = "forseti"

  composite_root_resources = ["organizations/${var.organization_id}"]
  server_grpc_allow_ranges = ["${var.server_grpc_allow_ranges}"]

  cscc_violations_enabled = true
  cscc_source_id          = "${var.cscc_source_id}"
}
