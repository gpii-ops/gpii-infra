# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/common/modules//aws-gcloud-dns"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

