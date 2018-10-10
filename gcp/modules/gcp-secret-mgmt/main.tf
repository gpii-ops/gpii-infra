terraform {
  backend "gcs" {}
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

module "gcp-secret-mgmt" {
  source = "/exekube-modules/gcp-secret-mgmt"

  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"
  encryption_keys    = "${var.encryption_keys}"
  storage_location   = "${var.storage_location}"
  keyring_name       = "${var.keyring_name}"
}

# Re-export variable. See https://www.terraform.io/docs/providers/terraform/d/remote_state.html#root-outputs-only
output "encryption_keys" {
  value = "${module.gcp-secret-mgmt.encryption_keys}"
}
