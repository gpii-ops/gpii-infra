# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//couchdb"
  }

  dependencies {
    paths = [
      "../../templater",
      "../../kube-system/helm-initializer",
      "../../kube-system/cert-manager",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

couchdb_replicas = 3
backup_deltas = "PT5M PT60M PT24H P7D P52W"
release_namespace = "gpii"
