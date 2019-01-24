# ↓ Module metadata

terragrunt = {
  terraform {
    source = "/project/modules//gcp-project"
  }
  dependencies {
    paths = ["../../dns-root"]
  }
  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ↓ Module configuration (empty means all default)

project_name    = "prd"

# This variable set an owner account in addition to the service accounts needed
# to manage the project
# The format of this variable must match the argument reference for the members
# of the role:
# https://www.terraform.io/docs/providers/google/r/google_project_iam.html#argument-reference
#
# root projects: dev,stg and prd don't need a project_owner. They will use the
# IAMs inherited from the org.
#
# The variable is set to avoid a failure in the execution of the module, but it won't be set.

project_owner   = "group:admins@test1.gpii.net"
