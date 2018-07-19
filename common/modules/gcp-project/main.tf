# this Terraform module creates the same resources as project_init script

terraform {
  backend "gcs" {}
}

variable "project_name" {}
variable "project_owner" {}
variable "billing_account" {}
variable "organization_id" {}

# compute the project_id to get the dns zone in JSON format
# I wasn't able to replicate this function using HCL code
data "external" "calculate_dns_zone" {
  program = ["python", "-c", "print(\"{\\\"zone\\\": \\\"\" + \".\".join(\"${google_project.project.project_id}\".split(\"-\")[::-1]) + \".net.\") + \"\\\"}\""]
}
 
resource "google_project" "project" {
  name            = "gpii-gcp-${var.project_name}"
  project_id      = "gpii-gcp-${var.project_name}"
  billing_account = "${var.billing_account}"
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

resource "google_project_iam_binding" "project" {
  project = "${google_project.project.project_id}"
  role    = "roles/owner"
  members = [
    "user:${var.project_owner}",
  ]
}

resource "google_service_account" "project" {
  account_id   = "projectowner"
  display_name = "Project owner service account"
  project      = "${google_project.project.project_id}"
}

resource "google_project_iam_binding" "admin-account-iam" {
  project = "${google_project.project.project_id}"
  role    = "roles/owner"
  members = [
    "serviceAccount:${google_service_account.project.email}",
  ]
}

resource "google_dns_managed_zone" "prod" {
  project     = "${google_project.project.project_id}"
  name        = "${google_project.project.project_id}-zone"
  dns_name    = "${lookup(data.external.calculate_dns_zone.result, "zone")}"
  description = "${google_project.project.project_id} DNS zone"
}

resource "google_storage_bucket" "project-tfstate" {
  project     = "${google_project.project.project_id}"
  name = "gpii-gcp-${var.project_name}-tfstate"
  versioning = {
    enabled = "true"
  }
}

