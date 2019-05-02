# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gpii-flushtokens"
  }

  dependencies {
    paths = [
      "../couchdb",
      "../istio",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

