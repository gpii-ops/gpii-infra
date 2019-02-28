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

cert_issuer_name     = "letsencrypt-production"

replica_count     = 3
requests_cpu      = "1000m"
requests_memory   = "256Mi"
limits_cpu        = "1000m"
limits_memory     = "256Mi"
