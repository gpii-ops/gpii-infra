provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

#
# resource "google_compute_global_address" "compute_global_address" {
#   name = "apps-ingress-ip"
# }
#
# resource "google_dns_managed_zone" "dns_managed_zone" {
#   name        = "apps-zone"
#   dns_name    = "apps.exekube.us."
#   description = "Apps DNS zone"
# }
#
# resource "google_dns_record_set" "dns_record_set" {
#   type         = "A"
#   ttl          = 3600
#   managed_zone = "apps-zone"
#   name         = "*.apps.exekube.us."
#   rrdatas      = ["${google_compute_global_address.compute_global_address.address}"]
# }
#
# output "global_dns_zone_servers" {
#   value = "${google_dns_managed_zone.dns_managed_zone.name_servers}"
# }
#
# output "global_static_ip_address" {
#   value = "${google_compute_global_address.compute_global_address.address}"
# }

