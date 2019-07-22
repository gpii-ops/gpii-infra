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

node_type = "n1-highcpu-4"
# Allow images from our test GCR.
binary_authorization_admission_whitelist_patterns = ["gcr.io/gpii-common-prd/*", "gcr.io/gpii2test-common-stg/*"]
