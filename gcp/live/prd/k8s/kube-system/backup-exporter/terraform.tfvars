# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//backup-exporter"
  }

  dependencies {
    paths = [
      "../k8s-snapshots",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

destination_bucket = "gs://gpii-backup-prd"
replica_count      = 3
schedule           = "0 0,12 * * *"
