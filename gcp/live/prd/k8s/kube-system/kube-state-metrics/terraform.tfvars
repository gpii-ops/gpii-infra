# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//kube-state-metrics"
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
