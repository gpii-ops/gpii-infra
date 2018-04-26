terraform {
  backend "gcs" {}
}

/*
variable "project_id" {}
variable "serviceaccount_key" {}
variable "encryption_keys" {}

module "gke_cluster" {
  source          = "/exekube-modules/gcp-secret-mgmt"
  encryption_keys = "${var.encryption_keys}"
}
*/

