# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//k8s-snapshots"
  }

  dependencies {
    paths = [
      "../helm-initializer",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
