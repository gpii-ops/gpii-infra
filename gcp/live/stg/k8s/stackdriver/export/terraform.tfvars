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
exported_logs_storage_class = "NEARLINE"
exported_logs_storage_region = ""
exported_logs_expire_after = "60"
