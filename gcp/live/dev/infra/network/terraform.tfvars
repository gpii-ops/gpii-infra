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
