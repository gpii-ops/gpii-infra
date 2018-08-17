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

couchdb_replicas = 2
backup_deltas = "PT5M PT15M PT45M"
release_namespace = "gpii"
