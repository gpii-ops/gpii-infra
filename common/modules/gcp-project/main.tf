# this Terraform module creates the same resources as project_init script and
# set the DNS zones structure.

terraform {
  backend "gcs" {}
}

variable "project_name" {}
variable "project_owner" {}
variable "billing_id" {}
variable "organization_id" {}

resource "google_project" "project" {
  name            = "gpii-gcp-${var.project_name}"
  project_id      = "gpii-gcp-${var.project_name}"
  billing_account = "${var.billing_id}"
  org_id          = "${var.organization_id}"
}

resource "google_project_services" "project" {
  project = "${google_project.project.project_id}"
  services = [
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "dns.googleapis.com"
  ]
}

resource "google_service_account" "project" {
  account_id   = "projectowner"
  display_name = "Project owner service account"
  project      = "${google_project.project.project_id}"
}

resource "google_project_iam_binding" "project" {
  project = "${google_project.project.project_id}"
  role    = "roles/owner"
  members = [
    "user:${var.project_owner}",
    "serviceAccount:${google_service_account.project.email}",
  ]
}

resource "google_dns_managed_zone" "project" {
  project     = "${google_project.project.project_id}"
  name        = "${google_project.project.project_id}-zone"
  dns_name    = "${lookup(data.external.calculate_dns_zone.result, "zone")}"
  description = "${google_project.project.project_id} DNS zone"
}

# Set the NS records in the parent zone of the parent project if the
# project_name has the pattern ${env}-${user}
resource "google_dns_record_set" "ns" {
  name         = "${replace(
                      replace(
                        google_project.project.project_id,
                        "/([a-z]+)-([a-z]+)-([a-z]+)-?([a-z]+)?/",
                        "$4.$3.$2.$1.net."),
                      "/^\\./",
                      "")
                    }"
  managed_zone = "${google_dns_managed_zone.project.name}"
  type         = "NS"
  ttl          = 3600
  project      = "gpii-gcp-${element(split("-", var.project_name), 0)}"
  rrdatas      = ["${google_dns_managed_zone.project.name_servers}"]
  count        = "${length(split("-", var.project_name)) == 2 ? 1 : 0}"
}

# Set the NS records in the gcp.gpii.net zone of the gpii-gcp-common-prd if the
# project name doesn't have a hyphen.
resource "google_dns_record_set" "ns-root" {
  name         = "${replace(
                      replace(
                        google_project.project.project_id,
                        "/([a-z]+)-([a-z]+)-([a-z]+)-?([a-z]+)?/",
                        "$4.$3.$2.$1.net."),
                      "/^\\./",
                      "")
                    }"
  managed_zone = "gcp-gpii-net"
  type         = "NS"
  ttl          = 3600
  project      = "gpii-gcp-common-prd"
  rrdatas      = ["${google_dns_managed_zone.project.name_servers}"]
  count        = "${length(split("-", var.project_name)) == 1 ? 1 : 0}"
}

resource "google_storage_bucket" "project-tfstate" {
  project     = "${google_project.project.project_id}"
  name = "gpii-gcp-${var.project_name}-tfstate"
  versioning = {
    enabled = "true"
  }
}

