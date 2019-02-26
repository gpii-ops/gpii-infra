# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//couchdb"
  }

  dependencies {
    paths = [
      "../../kube-system/helm-initializer",
      "../../kube-system/cert-manager"
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

backup_deltas     = "PT5M PT15M PT45M"
release_namespace = "gpii"

replica_count        = 2
requests_cpu         = "500m"
requests_memory      = "512Mi"
limits_cpu           = "1000m"
limits_memory        = "512Mi"
pv_capacity          = "10Gi"
pv_reclaim_policy    = "Delete"
pv_storage_class     = ""
pv_provisioner       = ""
execute_destroy_pvcs = "true"
execute_recover_pvcs = "false"
