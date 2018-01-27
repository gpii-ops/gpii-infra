terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket = "gpii-terraform-state"
      key = "${path_relative_to_include()}/terraform.tfstate"
      region = "us-east-2"
      encrypt = true

      # Tell Terraform to do locking using DynamoDB. Terragrunt will
      # automatically create this table for you if it doesn't already exist.
      dynamodb_table = "gpii-terraform-lock-table"
    }
  }

  terraform {
    # Force Terraform to keep trying to acquire a lock for up to 1 minute if someone else already has the lock
    extra_arguments "retry_lock" {
      arguments = [
        "-lock-timeout=1m"
      ]
      commands = [
        "init",
        "apply",
        "refresh",
        "import",
        "plan",
        "taint",
        "untaint",
        "destroy"
      ]

    }
  }
}
