# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gke-cluster"
  }

  dependencies {
    paths = [
      "../stackdriver/exclusion",
      "../stackdriver/export",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
