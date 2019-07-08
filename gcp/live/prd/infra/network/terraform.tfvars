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

# DNS zone names are dynamic (e.g. mrtyler.dev.gcp.gpii.net) so they will be
# injected from outside. (If they're not, defaulting to no DNS records is
# reasonable.)
dns_zones   = {}
dns_records = {}
