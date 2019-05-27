# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-monitoring-prd"
  }

  dependencies {
    paths = [
      "../../gpii/preferences",
      "../../gpii/flowmanager",
      "../lbm-prd"
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

use_auth_user_email = true
notification_email = "alerts+dev@raisingthefloor.org"
