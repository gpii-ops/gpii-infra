# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-export"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
exported_logs_force_destroy = "false"
exported_logs_storage_class = "COLDLINE"
exported_logs_expire_after = "730"
