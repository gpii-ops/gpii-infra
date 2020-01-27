terraform {
  backend "gcs" {}
}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

variable "common_environments" {
  default = ["prd", "stg"]
}

variable "project_id" {}
variable "notification_email" {}
variable "serviceaccount_key" {}
