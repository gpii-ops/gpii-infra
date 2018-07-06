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
