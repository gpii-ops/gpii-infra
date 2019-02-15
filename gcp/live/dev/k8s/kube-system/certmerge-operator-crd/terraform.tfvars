# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//certmerge-operator-crd"
  }

  dependencies {
    paths = [
      "../helm-initializer",
      "../certmerge-operator",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
