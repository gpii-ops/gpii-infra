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

resource "google_dns_managed_zone" "gpii_net" {
  name        = "gpii-net"
  dns_name    = "gpii.net."
  description = "gpii.net DNS zone"

  lifecycle {
    prevent_destroy = "true"
  }
}

resource "google_dns_record_set" "ns_test1_gpii_net" {
  name         = "test1.gpii.net."
  managed_zone = "${google_dns_managed_zone.gpii_net.name}"
  type         = "NS"
  ttl          = 3600
  rrdatas      = ["${google_dns_managed_zone.test1_gpii_net.name_servers}"]
}

resource "google_dns_record_set" "ns_gcp_gpii_net" {
  name         = "gcp.gpii.net."
  managed_zone = "${google_dns_managed_zone.gpii_net.name}"
  type         = "NS"
  ttl          = 3600
  rrdatas      = ["${google_dns_managed_zone.main.name_servers}"]
}

resource "google_dns_managed_zone" "test1_gpii_net" {
  name        = "test1-gpii-net"
  dns_name    = "test1.gpii.net."
  description = "test1.gpii.net DNS zone"

  lifecycle {
    prevent_destroy = "true"
  }
}

resource "google_dns_record_set" "ns_gcp_test1_gpii_net" {
  name         = "gcp.test1.gpii.net."
  managed_zone = "${google_dns_managed_zone.test1_gpii_net.name}"
  type         = "NS"
  ttl          = 3600
  rrdatas      = ["${google_dns_managed_zone.gcp_test1_gpii_net.name_servers}"]
}

resource "google_dns_managed_zone" "gcp_test1_gpii_net" {
  name        = "gcp-test1-gpii-net"
  dns_name    = "gcp.test1.gpii.net."
  description = "gcp.test1.gpii.net DNS zone"

  lifecycle {
    prevent_destroy = "true"
  }
}

# This resource should be named "gcp_gpii_net" but we are going to preserve this in order to avoid missmatching between AWS and GCP.
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
