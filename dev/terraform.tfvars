# Override remote_state config to make it more distinct. While we want shared
# production and stage environments, we don't want to share dev or testing
# environments.
#
# NOTE: var.environment (e.g. "stg") MUST match in all included terragrunt
# stanzas. This means var.environment MUST match the name of the environment on
# disk since the name on disk is used in calculating paths elsewhere.
terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket = "gpii-terraform-state"
      # We're one level lower in the hierarchy, so add that back to the
      # beginning.
      key = "dev-${get_env("USER", "unknown-user")}/${path_relative_to_include()}/terraform.tfstate"
      region = "us-east-2"
      encrypt = true

      # Tell Terraform to do locking using DynamoDB. Terragrunt will
      # automatically create this table for you if it doesn't already exist.
      lock_table = "gpii-terraform-lock-table"
    }
  }
}
