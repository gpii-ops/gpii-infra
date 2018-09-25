# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-export"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
exports = {
  # Captures interactions with many Google products, including GCE, GS, IAM,
  # and more.
  #
  # TODO: This is a lot less noisy if we add "AND NOT operation.producer=k8s.io".
  "cloudaudit-activity" = "logName=projects/__var.project_id__/logs/cloudaudit.googleapis.com%2Factivity"

  # Captures Google Storage and KMS events
  "cloudaudit-data-access" = "logName=projects/__var.project_id__/logs/cloudaudit.googleapis.com%2Fdata_access"

  # Captures events for products within GCE, such as Snapshots, Instance
  # Groups, Firewalls, etc.
  "compute-activity" = "logName=projects/__var.project_id__/logs/compute.googleapis.com%2Factivity_log"
}
