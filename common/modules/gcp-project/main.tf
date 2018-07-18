# this Terraform module creates the same resources as project_init script

terraform {
  backend "gcs" {}
}

variable "project_name" {}
variable "project_owner" {}
variable "billing_account" {}
variable "organization_id" {}

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
  project     = "${google_project.project.project_id}"
  role        = "roles/owner"
  members = [
    "user:${var.project_owner}",
  ]
}

resource "google_service_account" "project" {
  account_id   = "projectowner"
  display_name = "Project owner service account"
  project      = "${google_project.project.project_id}"
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = "${google_service_account.project.unique_id}"
  role    = "roles/owner"
  members = [
    "serviceAccount:${google_service_account.project.email}",
  ]
}

resource "google_storage_bucket" "project-tfstate" {
  name = "gpii-gcp-${var.project_name}-tfstate"
  versioning = {
    enabled = "true"
  }
}

