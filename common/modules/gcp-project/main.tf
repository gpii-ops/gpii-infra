# this Terraform module creates the same resources as project_init script and
# set the DNS zones structure.

terraform {
  backend "gcs" {}
}

variable "project_name" {} # name of the project to create

variable "project_owner" {}

variable "billing_id" {}

variable "organization_id" {}

variable "serviceaccount_key" {}

variable "project_id" {} # id of the project which owns the credentials used by the provider


provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "us-central1"
}


locals  {
  dnsname = "${replace(
              replace(
                google_project.project.name,
                "/([\w]+)-([\w]+)-([\w]+)-?([\w]+)?/",
                "$4.$3.$2.$1.net."),
              "/^\\./",
              "")
            }"
}

resource "google_project" "project" {
  name            = "gpii-gcp-${var.project_name}"
  project_id      = "gpii-gcp-${var.project_name}"
  billing_account = "${var.billing_id}"
  org_id          = "${var.organization_id}"
}

resource "google_project_services" "project" {
  project = "${google_project.project.project_id}"
  services = [
    "oslogin.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "appengine.googleapis.com",
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
    "group:ops@raisingthefloor.org",
    "serviceAccount:${google_service_account.project.email}",
    "serviceAccount:projectowner@gpii-common-prd.iam.gserviceaccount.com",
  ]
}

resource "google_dns_managed_zone" "project" {
  project     = "${google_project.project.project_id}"
  name        = "${google_project.project.project_id}-zone"
  dns_name    = "${local.dnsname}"
  description = "${google_project.project.project_id} DNS zone"
  depends_on  = ["google_project_services.project",
                 "google_project_iam_binding.project"]
}

# Set the NS records in the parent zone of the parent project if the
# project_name has the pattern ${env}-${user}
resource "google_dns_record_set" "ns" {
  name         = "${local.dnsname}"
  managed_zone = "gpii-gcp-${element(split("-", var.project_name), 0)}-zone"
  type         = "NS"
  ttl          = 3600
  project      = "gpii-gcp-${element(split("-", var.project_name), 0)}"
  rrdatas      = ["${google_dns_managed_zone.project.name_servers}"]
  count        = "${length(split("-", var.project_name)) == 2 ? 1 : 0}"
}

# Set the NS records in the gcp.gpii.net zone of the gpii-gcp-common-prd if the
# project name doesn't have a hyphen.
resource "google_dns_record_set" "ns-root" {
  name         = "${local.dnsname}"
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

