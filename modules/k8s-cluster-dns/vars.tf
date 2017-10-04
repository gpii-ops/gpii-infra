variable "environment" {}

output "cluster_dns_zone_id" {
  value = "${aws_route53_zone.main.zone_id}"
}
