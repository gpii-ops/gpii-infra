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

resource "google_dns_managed_zone" "root_zone" {
  name        = "${replace(var.organization_domain, ".", "-")}"
  dns_name    = "${var.organization_domain}."
  description = "root ${var.organization_domain} DNS zone"

  lifecycle {
    prevent_destroy = "true"
  }
}

# Only needed to create the NS registry of test.gpii.net in gpii.net zone
data "google_dns_managed_zone" "test_gpii_net" {
  count   = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  name    = "test-gpii-net"
  project = "gpii2test-common-stg"
}

resource "google_dns_record_set" "ns_test_gpii_net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  name         = "test.gpii.net."
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  type         = "NS"
  ttl          = 3600
  rrdatas      = ["${data.google_dns_managed_zone.test_gpii_net.0.name_servers}"]
}

resource "google_dns_record_set" "ns_main" {
  name         = "gcp.${var.organization_domain}."
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  type         = "NS"
  ttl          = 3600
  rrdatas      = ["${google_dns_managed_zone.main.name_servers}"]
}

# This resource should be named "gcp_zone" but we are going to preserve this in order to avoid missmatching between AWS and GCP.
# Once all the DNS is set at GCP we can rename this resource and apply the plan being sure that all the zones are well referenced.
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
