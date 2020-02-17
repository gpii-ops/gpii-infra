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

# Cloud Resource Manager system account to exclude in IAM modification LBM
variable "crm_sa" {
  default = "one-platform-tenant-manager@system.gserviceaccount.com"
}

variable "nonce" {}
variable "project_id" {}
variable "organization_id" {}
variable "notification_email" {}
variable "common_project_id" {}
variable "domain_name" {}
variable "serviceaccount_key" {}
variable "env" {}

variable "use_auth_user_email" {
  default = false
}

variable "auth_user_email" {}
variable "secret_slack_auth_token" {}
