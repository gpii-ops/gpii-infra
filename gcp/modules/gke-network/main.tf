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
variable "create_static_ip_address" {}

# Terragrunt variables
variable "static_ip_region" {}

variable "cluster_subnets" {
  type = "map"
}

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
  source = "/exekube-modules/gke-network"

  dns_zones                = "${var.dns_zones}"
  dns_records              = "${var.dns_records}"
  cluster_subnets          = "${var.cluster_subnets}"
  static_ip_region         = "${var.static_ip_region}"
  create_static_ip_address = "${var.create_static_ip_address}"
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "static_ip_address" {
  value = "${module.gke_network.static_ip_address}"
}

output "dns_zones" {
  value = "${module.gke_network.dns_zones}"
}

output "dns_zone_servers" {
  value = "${module.gke_network.dns_zone_servers}"
}
