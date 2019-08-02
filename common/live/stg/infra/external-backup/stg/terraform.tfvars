# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gcp-external-backup"
  }
  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

source_project_name = "stg"
days_until_delete   = "2"
