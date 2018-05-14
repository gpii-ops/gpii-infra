variable "record_name" {}

variable "project_id" {}

variable "serviceaccount_key" {}


provider "aws" {
  version = "~> 1.8"
  region = "us-east-2"
}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "us-central1"
}
 

resource "google_dns_managed_zone" "main" {
  name        = "${var.record_name}-gpii-net"
  dns_name    = "${var.record_name}.gpii.net."
  description = "${var.record_name} DNS zone"
  lifecycle   {
     prevent_destroy = "true"
  }
}


output "gcp_name_servers" {
  value = "${google_dns_managed_zone.main.name_servers}"
}

