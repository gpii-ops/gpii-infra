# This code will create zones at GCP
#
# * gcp.$organization_domain
#
# The zone gcp will be delegated to Google DNS.

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "gcs" {}
}

variable "project_id" {}

variable "serviceaccount_key" {}

variable "infra_region" {}

variable "organization_domain" {
  default = "gpii.net"
}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "${var.infra_region}"
}

resource "google_dns_managed_zone" "main" {
  name        = "gcp-${replace(var.organization_domain, ".", "-")}"
  dns_name    = "gcp.${var.organization_domain}."
  description = "gcp DNS zone"

  lifecycle {
    prevent_destroy = "true"
  }
}

output "gcp_name_servers" {
  value = "${google_dns_managed_zone.main.name_servers}"
}

output "gcp_name" {
  value = "${google_dns_managed_zone.main.name}"
}
