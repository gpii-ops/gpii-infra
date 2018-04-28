# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//helm-initializer"
  }

  dependencies {
    paths = [
      "../../cluster",
      "../../kube-system/administration-tasks",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

tiller_namespace = "gpii"
