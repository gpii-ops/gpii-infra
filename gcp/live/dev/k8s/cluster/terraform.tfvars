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

# Team decided to temporarily change node flavor for dev clusters
# until GCP resource exhaustion issue is solved:
# https://issues.gpii.net/browse/GPII-3697
#
# node_type = "n1-standard-2"

node_type = "n1-highcpu-4"
