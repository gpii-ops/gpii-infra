# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//cert-manager"
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
