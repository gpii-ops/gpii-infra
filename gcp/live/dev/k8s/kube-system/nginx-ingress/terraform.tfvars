# ↓ Module metadata
terragrunt = {
  terraform {
    source = "/project/modules//nginx-ingress"
  }

  dependencies {
    paths = [
      "../helm-initializer",
    ]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

load_balancer_ip = ""
