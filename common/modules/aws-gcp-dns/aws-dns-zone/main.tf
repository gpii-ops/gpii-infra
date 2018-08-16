variable "record_name" {}

variable "aws_zone_id" {}

variable "ns_records" {
  type        = "list"
  default     = []
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
  zone_id = "${var.aws_zone_id}"
  name    = "${aws_route53_zone.main.name}"
  type    = "NS"
  ttl     = "60"
  # Tricky list assignement, more info: https://github.com/hashicorp/terraform/issues/13733
  records = ["${split(",", length(var.ns_records) == 0 ? join(",",aws_route53_zone.main.name_servers) : join(",",var.ns_records))}"]
  lifecycle   {
     prevent_destroy = "true"
  }
}

output "aws_name" {
  value = "${aws_route53_zone.main.name}"
}

