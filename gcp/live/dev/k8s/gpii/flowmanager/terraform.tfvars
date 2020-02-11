# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gpii-flowmanager"
  }

  dependencies {
    paths = [
      "../../kube-system/cert-manager",
      "../couchdb",
      "../istio",
      "../preferences",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

cert_issuer_name  = "letsencrypt-staging"
replica_count     = 2
requests_cpu      = "250m"
requests_memory   = "256Mi"
limits_cpu        = "500m"
limits_memory     = "256Mi"
