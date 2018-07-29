terragrunt = {
  # Configure Terragrunt to automatically store tfstate files in an GCS bucket
  remote_state {
    backend = "gcs"

    config {
      prefix         = "${path_relative_to_include()}"
      credentials    = "${get_env("TF_VAR_serviceaccount_key", "")}"
      bucket         = "${get_env("TF_VAR_tfstate_bucket", "")}"
      encryption_key = "${get_env("TF_VAR_tfstate_encryption_key", "")}"
    }
  }

  terraform {
    extra_arguments "auto_approve" {
      commands  = ["apply"]
      arguments = ["-auto-approve"]
    }

    extra_arguments "force_destroy" {
      commands  = ["destroy"]
      arguments = ["-force"]
    }
  }
}
