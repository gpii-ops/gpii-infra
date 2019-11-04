# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

# This email will receive all the alerts of the backups exported by prd and stg
notification_email = "alerts+prd@raisingthefloor.org"
