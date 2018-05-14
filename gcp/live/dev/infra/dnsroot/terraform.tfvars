# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/common/modules//aws-gcp-dns"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

