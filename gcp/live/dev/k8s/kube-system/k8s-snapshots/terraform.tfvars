# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//k8s-snapshots"
  }

  dependencies {
    paths = [
      "../../gpii/couchdb",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
