
variable "recordname" {}

variable "gcp_project" {}


provider "aws" {
  version = "~> 1.8"
  region = "us-east-2"
}

provider "google" {
  credentials = "${file("key.json")}"
  project     = "${var.gcp_project}"
  region      = "us-central1"
}


resource "aws_route53_zone" "main" {
  name = "${var.recordname}.gpii.net"
  force_destroy = true

  tags {
    Terraform = true
  }
}


resource "google_dns_managed_zone" "main" {
  name        = "${var.recordname}-gpii-net"
  dns_name    = "${var.recordname}.gpii.net."
  description = "${var.recordname} DNS zone"
}


resource "aws_route53_record" "main_ns" {
  zone_id = "Z26C1YEN96KOGI"  # Unmanaged route53 zone for gpii.net
  name    = "${aws_route53_zone.main.name}"
  type    = "NS"
  ttl     = "60"

  records = [
    "${google_dns_managed_zone.main.name_servers.0}", # Google NS
    "${google_dns_managed_zone.main.name_servers.1}",
    "${google_dns_managed_zone.main.name_servers.2}",
    "${google_dns_managed_zone.main.name_servers.3}",
  ]
}


output "cluster_dns_zone_id" {
  value = "${aws_route53_zone.main.zone_id}"
}

