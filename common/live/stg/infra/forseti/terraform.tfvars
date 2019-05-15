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

cscc_source_id = "organizations/327626828918/sources/4225144863199177855"
