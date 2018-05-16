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

variable "cluster_subnets" {
  default = {
    "0" = "us-central1,10.16.0.0/20,10.17.0.0/16,10.18.0.0/16"
  }
}

variable "static_ip_region" {
  default = "us-central1"
}

# ------------------------------------------------------------------------------
# Modules and resources
# ------------------------------------------------------------------------------

module "gke_network" {
  source             = "/exekube-modules/gke-network"

  dns_zones        = "${var.dns_zones}"
  dns_records      = "${var.dns_records}"
  cluster_subnets  = "${var.cluster_subnets}"
  static_ip_region = "${var.static_ip_region}"
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
