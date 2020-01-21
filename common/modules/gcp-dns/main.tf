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
  description = "Root ${var.organization_domain} DNS zone"

  lifecycle {
    prevent_destroy = "true"
  }
}

# Override NS record created by google_dns_managed_zone
# to set proper TTL
resource "google_dns_record_set" "root_zone" {
  name         = "${google_dns_managed_zone.root_zone.dns_name}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  type         = "NS"
  ttl          = 3600
  project      = "${var.project_id}"
  rrdatas      = ["${google_dns_managed_zone.root_zone.name_servers}"]
  depends_on   = ["google_dns_managed_zone.root_zone"]
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

resource "google_dns_managed_zone" "main" {
  name        = "gcp-${replace(var.organization_domain, ".", "-")}"
  dns_name    = "gcp.${var.organization_domain}."
  description = "Main GCP part DNS zone"

  lifecycle {
    prevent_destroy = "true"
  }
}

# Override NS record created by google_dns_managed_zone
# to set proper TTL
resource "google_dns_record_set" "main" {
  name         = "${google_dns_managed_zone.main.dns_name}"
  managed_zone = "${google_dns_managed_zone.main.name}"
  type         = "NS"
  ttl          = 3600
  project      = "${var.project_id}"
  rrdatas      = ["${google_dns_managed_zone.main.name_servers}"]
  depends_on   = ["google_dns_managed_zone.main"]
}

output "gcp_name_servers" {
  value = "${google_dns_managed_zone.main.name_servers}"
}

output "gcp_name" {
  value = "${google_dns_managed_zone.main.name}"
}
