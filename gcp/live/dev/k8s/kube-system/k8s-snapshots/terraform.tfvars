# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//k8s-snapshots"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
