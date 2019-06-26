# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//gpii-dataloader"
  }

  dependencies {
    paths = [
      "../couchdb",
      "../common",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

