# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//locust"
  }

  dependencies {
    paths = [
      "../istio",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }

}

# ↓ Module configuration (empty means all default)

