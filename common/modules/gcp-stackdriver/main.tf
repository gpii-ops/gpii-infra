terraform {
  backend "gcs" {}
}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

provider "google-beta" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

variable "project_id" {}
variable "organization_id" {}
variable "notification_email" {}
variable "common_project_id" {}
variable "domain_name" {}
variable "serviceaccount_key" {}
variable "env" {}
