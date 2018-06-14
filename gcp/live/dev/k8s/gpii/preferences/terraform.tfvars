# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gpii-preferences"
  }

  dependencies {
    paths = [
      "../../kube-system/cert-manager",
      "../nginx-ingress",
      "../couchdb",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

