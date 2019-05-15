terraform {
  backend "gcs" {}
}

variable "serviceaccount_key" {}
variable "project_id" {}
variable "infra_region" {}

variable "ip_cidr_range" {
  default = "10.11.0.0/16"
}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "${var.infra_region}"
}

resource "google_compute_network" "forseti" {
  name                    = "forseti"
  project                 = "${var.project_id}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "forseti" {
  name                     = "forseti"
  project                  = "${var.project_id}"
  network                  = "${google_compute_network.forseti.self_link}"
  ip_cidr_range            = "${var.ip_cidr_range}"
  region                   = "${var.infra_region}"
  private_ip_google_access = true
}
