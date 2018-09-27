# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gcp-project"
  }
  dependencies {
    paths = ["../zone"]
  }
  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

project_name    = "dev-jhernandez"
project_owner   = "javi@raisingthefloor.org"
