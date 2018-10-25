# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gcp-stackdriver-alerting"
  }

  dependencies {
    paths = [
      "../../gpii/preferences",
      "../../gpii/flowmanager",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
