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

node_type          = "n1-standard-2"
initial_node_count = 2
region             = "us-east1"
additional_zones   = ["us-east1-b", "us-east1-c"]
