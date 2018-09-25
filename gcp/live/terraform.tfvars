terragrunt = {
  # Configure Terragrunt to automatically store tfstate files in an GCS bucket
  remote_state {
    backend = "gcs"

    config {
      credentials    = "${get_env("TF_VAR_serviceaccount_key", "")}"
      bucket         = "${get_env("TF_VAR_project_id", "")}-tfstate"
      prefix         = "${path_relative_to_include()}"
      # TODO: Next line needs to be uncommented back once Terraform issue with GCS backend encryption is fixed
      # https://issues.gpii.net/browse/GPII-3329
      # encryption_key = "${get_env("TF_VAR_key_tfstate_encryption_key", "")}"
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
