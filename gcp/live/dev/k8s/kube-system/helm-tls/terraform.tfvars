# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//helm-tls"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

