# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-monitoring"
  }

  dependencies {
    paths = [
      "../../gpii/preferences",
      "../../gpii/flowmanager"
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

notification_email = "alerts+prd@raisingthefloor.org"
