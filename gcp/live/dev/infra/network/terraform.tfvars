# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gke-network"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

# create_static_ip_address = false

dns_zones = {
  gcp-gpii-net = "gcp.gpii.net."
}

dns_records = {
  gcp-gpii-net = "*.gcp.gpii.net."
}

cluster_subnets = {
    "0" = "us-central1,10.16.0.0/20,10.17.0.0/16,10.18.0.0/16"
}

static_ip_region = "us-central1"
