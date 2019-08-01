# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gcp-dns"
  }
  include = {
    path = "${find_in_parent_folders()}"
  }
}

