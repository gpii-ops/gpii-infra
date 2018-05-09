# This code will create two zones at AWS Route53
#
# * aws.gpii.net
# * gcp.gpii.net
#
# The zone gcp will be delegated to Google DNS. 

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "gcs" {}
}

variable "project_id" {}

variable "serviceaccount_key" {}


provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "us-central1"
}
 
provider "aws" {
  version = "~> 1.8"
  region = "us-east-2"
}
 

module "aws_zone" {
  source = "./awsdnszone"
  recordname = "aws"
  serviceaccount_key = "${var.serviceaccount_key}"
  project_id = "${var.project_id}"
}

module "gcp_zone" {
  source = "./gcpdnszone"
  recordname = "gcp"
  serviceaccount_key = "${var.serviceaccount_key}"
  project_id = "${var.project_id}" 
}
 
module "aws-gcp_zone" {
  source = "./awsdnszone"
  recordname = "gcp"
  nsrecords = "${module.gcp_zone.gcp_name_servers}"
  serviceaccount_key = "${var.serviceaccount_key}"
  project_id = "${var.project_id}"  
}

