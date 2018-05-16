variable "record_name" {}


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

