resource "aws_route53_zone" "main" {
  name          = "${var.environment}.gpii.net"
  force_destroy = true

  tags {
    Environment = "${var.environment}"
    Terraform   = true
  }
}

resource "aws_route53_record" "main_ns" {
  zone_id = "Z26C1YEN96KOGI"                # Unmanaged route53 zone for gpii.net
  name    = "${aws_route53_zone.main.name}"
  type    = "NS"
  ttl     = "60"

  records = [
    "${aws_route53_zone.main.name_servers.0}",
    "${aws_route53_zone.main.name_servers.1}",
    "${aws_route53_zone.main.name_servers.2}",
    "${aws_route53_zone.main.name_servers.3}",
  ]
}
