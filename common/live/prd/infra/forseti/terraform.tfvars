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
client_type = "n1-standard-1"
cscc_source_id = "organizations/247149361674/sources/8182570756213435894"
