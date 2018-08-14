# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gcp-api-mgmt"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

waiting_period = 60
