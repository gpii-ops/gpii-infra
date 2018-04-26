# ------------------------------------------------------------------------------
# Terraform & Provider Config
# ------------------------------------------------------------------------------

terraform {
  backend "gcs" {}
}

# ------------------------------------------------------------------------------
# Input variables
# ------------------------------------------------------------------------------

variable "project_id" {}
variable "serviceaccount_key" {}

variable "dns_zones" {
  default = {}
}

variable "dns_records" {
  default = {}
}

# ------------------------------------------------------------------------------
# Modules and resources
# ------------------------------------------------------------------------------

module "gke_network" {
  source             = "/exekube-modules/gke-network"
  project_id         = "${var.project_id}"
  serviceaccount_key = "${var.serviceaccount_key}"

  dns_zones   = "${var.dns_zones}"
  dns_records = "${var.dns_records}"
}

# ------------------------------------------------------------------------------
# Outuputs
# ------------------------------------------------------------------------------

/*
output "static_ip_address" {
  value = "${module.gke_network.static_ip_address}"
}
*/

output "dns_zones" {
  value = "${module.gke_network.dns_zones}"
}

output "dns_zone_servers" {
  value = "${module.gke_network.dns_zone_servers}"
}
