# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gpii-istio"
  }

  dependencies {
    paths = [
      "../../cluster",
      "../../istio",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)
