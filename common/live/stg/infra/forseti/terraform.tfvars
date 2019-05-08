# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//forseti"
  }
  dependencies {
    paths = ["../forseti-network"]
  }
  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

server_grpc_allow_ranges = "10.11.0.0/16"
cscc_source_id = "organizations/327626828918/sources/4225144863199177855"
