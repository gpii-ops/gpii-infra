# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//couchdb"
  }

  dependencies {
    paths = [
      "../../kube-system/helm-initializer",
      "../../kube-system/cert-manager",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

backup_deltas     = "PT5M PT60M PT4H PT24H P7D"
release_namespace = "gpii"

replica_count        = 3
requests_cpu         = "1000m"
requests_memory      = "512Mi"
limits_cpu           = "1000m"
limits_memory        = "512Mi"
pv_capacity          = "10Gi"
pv_reclaim_policy    = "Delete"
pv_storage_class     = "pd-ssd"
pv_provisioner       = "kubernetes.io/gce-pd"
execute_destroy_pvcs = "false"
execute_recover_pvcs = "true"
