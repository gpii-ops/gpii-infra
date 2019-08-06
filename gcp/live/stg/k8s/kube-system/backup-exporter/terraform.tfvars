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

# `destination_bucket` - The destination GCS bucket, i.e "gpii-backup-external-prd".
destination_bucket = "gpii-backup-stg"

# `replica_count` - the number of CouchDB replicas that the cluster has. This is important for copying all the snapshots of the cluster at the same time.
replica_count      = 3

# `schedule` - Follows the same format as a Cron Job. i.e: `*/10 * * * *` to execute the task every 10 minutes.
schedule           = "0 0,12 * * *"
