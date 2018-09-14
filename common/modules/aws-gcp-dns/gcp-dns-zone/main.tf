variable "record_name" {}

variable "organization_domain" {}
 

resource "google_dns_managed_zone" "main" {
  name        = "${var.record_name}-${replace(var.organization_domain, ".", "-")}"
  dns_name    = "${var.record_name}.${var.organization_domain}."
  description = "${var.record_name} DNS zone"
  lifecycle   {
     prevent_destroy = "true"
  }
}


output "gcp_name_servers" {
  value = "${google_dns_managed_zone.main.name_servers}"
}

output "gcp_name" {
  value = "${google_dns_managed_zone.main.name}"
}

