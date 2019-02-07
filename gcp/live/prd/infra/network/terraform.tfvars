# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gke-network"
  }

  dependencies {
    paths = [
      "../api-mgmt",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

create_static_ip_address = true

# DNS zone names are dynamic (e.g. mrtyler.dev.gcp.gpii.net) so they will be
# injected from outside. (If they're not, defaulting to no DNS records is
# reasonable.)
dns_zones = {}
dns_records = {}

static_ip_region = "us-central1"
cluster_subnets  = { "0" = "us-central1,10.16.0.0/20,10.17.0.0/16,10.18.0.0/16" }
