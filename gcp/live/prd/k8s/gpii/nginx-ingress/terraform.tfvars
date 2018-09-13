# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//nginx-ingress"
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
