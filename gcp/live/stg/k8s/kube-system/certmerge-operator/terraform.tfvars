# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//certmerge-operator"
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
