variable "record_name" {}

variable "ns_records" {
  type        = "list"
  default     = []
}

variable "project_id" {}

variable "serviceaccount_key" {}


provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "us-central1"
}
 
provider "aws" {
  version = "~> 1.8"
  region = "us-east-2"
}
 

resource "aws_route53_zone" "main" {
  name = "${var.record_name}.gpii.net"
  lifecycle   {
     prevent_destroy = "true"
  } 
  tags {
    Terraform = true
  }
}


resource "aws_route53_record" "main_ns" {
  zone_id = "Z26C1YEN96KOGI"  # Unmanaged route53 zone for gpii.net
  name    = "${aws_route53_zone.main.name}"
  type    = "NS"
  ttl     = "60"
  # Tricky list assignement, more info: https://github.com/hashicorp/terraform/issues/13733
  records = ["${split(",", length(var.ns_records) == 0 ? join(",",aws_route53_zone.main.name_servers) : join(",",var.ns_records))}"]
  lifecycle   {
     prevent_destroy = "true"
  }
}

