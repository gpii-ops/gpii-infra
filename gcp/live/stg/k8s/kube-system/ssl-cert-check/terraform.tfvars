# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//ssl-cert-check"
  }

  dependencies {
    paths = [
      "../helm-initializer",
      "../service-account-assigner",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
