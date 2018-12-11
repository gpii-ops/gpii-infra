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

replica_count     = 2
requests_cpu      = "25m"
requests_memory   = "128Mi"
limits_cpu        = "50m"
limits_memory     = "128Mi"
