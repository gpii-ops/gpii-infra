# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gpii-flowmanager"
  }

  dependencies {
    paths = [
      "../../kube-system/nginx-ingress",
      "../../kube-system/cert-manager",
      "../couchdb",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

