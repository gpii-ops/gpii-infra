# This code will create two zones at AWS Route53
#
# * aws.$organization_domain
# * gcp.$organization_domain
#
# The zone gcp will be delegated to Google DNS.

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "gcs" {}
}

variable "project_id" {}

variable "serviceaccount_key" {}

variable "organization_domain" {
  default = "gpii.net"
}

variable "aws_zone_id" {
  default = "Z26C1YEN96KOGI" # Unmanaged route53 zone for gpii.net
}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "us-central1"
}

provider "aws" {
  version = "~> 1.8"
  region  = "us-east-2"
}

module "aws_zone" {
  source              = "./aws-dns-zone"
  record_name         = "aws"
  aws_zone_id         = "${var.aws_zone_id}"
  organization_domain = "${var.organization_domain}"
}

module "gcp_zone" {
  source              = "./gcp-dns-zone"
  record_name         = "gcp"
  organization_domain = "${var.organization_domain}"
}

module "gcp_zone_in_aws" {
  source              = "./aws-dns-zone"
  record_name         = "gcp"
  ns_records          = "${module.gcp_zone.gcp_name_servers}"
  aws_zone_id         = "${var.aws_zone_id}"
  organization_domain = "${var.organization_domain}"
}
