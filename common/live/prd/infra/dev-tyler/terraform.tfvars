# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gcp-project"
  }
  dependencies {
    paths = ["../dev-zone"]
  }
  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

project_name    = "dev-tyler"
project_owner   = "tyler@raisingthefloor.org"

