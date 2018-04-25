# First we create the two managed zones at AWS and Google DNS


resource "aws_route53_zone" "main" {
  name = "${var.environment}.gpii.net"
  force_destroy = true

  tags {
    Environment = "${var.environment}"
    Terraform = true
  }
}


resource "google_dns_managed_zone" "main" {
  name        = "${var.environment}-gpii-net"
  dns_name    = "${var.environment}.gpii.net."
  description = "${var.environment} DNS zone"
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

