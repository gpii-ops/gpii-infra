# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//helm-initializer"
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

