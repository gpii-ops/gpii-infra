# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//aws-gcp-dns"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

