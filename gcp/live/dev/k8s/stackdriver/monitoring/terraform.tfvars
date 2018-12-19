# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-monitoring"
  }

  dependencies {
    paths = [
      "../../gpii/preferences",
      "../../gpii/flowmanager",
      "../lbm"
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

ssl_enabled_uptime_checks = false

# This variable can be overridden by TF_VAR_auth_user_email in case latter is present
notification_email = "alerts+dev@raisingthefloor.org"
