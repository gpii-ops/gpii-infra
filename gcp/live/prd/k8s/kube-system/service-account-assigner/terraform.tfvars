# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//service-account-assigner"
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
