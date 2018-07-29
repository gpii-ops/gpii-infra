terraform {
  backend "gcs" {}
}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

variable "project_id" {}
variable "serviceaccount_key" {}
variable "keyring_name" {}

variable "encryption_keys" {
  type = "list"
}

variable "storage_location" {
  default = "us-central1"
}

variable "tfstate_bucket" {}

module "gcp-secret-mgmt" {
  source = "/exekube-modules/gcp-secret-mgmt"

  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"
  encryption_keys    = "${var.encryption_keys}"
  storage_location   = "${var.storage_location}"
  keyring_name       = "${var.keyring_name}"
}

resource "google_storage_bucket" "tfstate_encrypted" {
  name          = "${var.tfstate_bucket}-encrypted"
  location      = "${var.storage_location}"
  force_destroy = true
  storage_class = "REGIONAL"
}
