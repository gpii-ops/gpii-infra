# ------------------------------------------------------------------------------
# Terraform & Provider Config
# ------------------------------------------------------------------------------

terraform {
  backend "gcs" {}
}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"
}

# ------------------------------------------------------------------------------
# Input variables
# ------------------------------------------------------------------------------

variable "project_id" {}
variable "serviceaccount_key" {}

variable "cluster_subnets" {
  default = "10.16.0.0/20,10.17.0.0/16,10.18.0.0/16"
}

# Terragrunt variables
variable "infra_region" {}

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

  dns_zones   = "${var.dns_zones}"
  dns_records = "${var.dns_records}"

  cluster_subnets = {
    "0" = "${var.infra_region},${var.cluster_subnets}"
  }

  static_ip_region         = "${var.infra_region}"
  create_static_ip_address = false
  delete_default_network   = false
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "dns_zones" {
  value = "${module.gke_network.dns_zones}"
}

output "dns_zone_servers" {
  value = "${module.gke_network.dns_zone_servers}"
}
