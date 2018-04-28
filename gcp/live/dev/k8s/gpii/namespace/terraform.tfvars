# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//k8s-namespace"
  }

  dependencies {
    paths = [
      "../../cluster",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

namespace_name = "gpii"
