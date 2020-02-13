# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//late-alerts"
  }

  dependencies {
    paths = [
      "../cluster",
      "../stackdriver/monitoring",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
