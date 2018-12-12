# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//couchdb-prometheus-exporter"
  }

  dependencies {
    paths = [
      "../couchdb",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
###replica_count = 1
replica_count = 4
