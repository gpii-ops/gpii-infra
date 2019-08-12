# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//couchdb"
  }

  dependencies {
    paths = [
      "../../kube-system/helm-initializer",
      "../../kube-system/cert-manager",
      "../istio",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

backup_deltas     = "PT5M PT15M PT45M"
release_namespace = "gpii"

requests_cpu         = "500m"
requests_memory      = "512Mi"
limits_cpu           = "1000m"
limits_memory        = "512Mi"
pv_capacity          = "10Gi"
pv_reclaim_policy    = "Delete"
pv_storage_class     = ""
pv_provisioner       = ""
# WARNING: If changing this value to "false", see
# https://issues.gpii.net/browse/GPII-3742?focusedCommentId=37601&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-37601
# for an additional manual step. (Otherwise, your next deployment will destroy
# your PVCs immediately :\.)
execute_destroy_pvcs = "true"
execute_recover_pvcs = "false"
