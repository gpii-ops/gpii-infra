variable "nonce" {}

variable "gcloud_timeout" {
  default = 30
}

resource "null_resource" "add_audit_config" {
  triggers = {
    nonce = "${var.nonce}"
  }

  depends_on = [
    "google_project_iam_policy.project",
  ]

  provisioner "local-exec" {
    command = <<EOF
      set -e

      expected_audit_configs="$(echo '[${join(
        ",",
        formatlist(
          "{\"auditLogConfigs\":[{\"logType\":\"DATA_READ\"},{\"logType\":\"DATA_WRITE\"}],\"service\":\"%s\"}",
          concat(
            var.apis_with_audit_configuration,
            var.apis_solely_for_audit_configuration
          )
        )
      )}]' | jq -c -r -S .)"

      current_iam_policy="$(timeout -t ${var.gcloud_timeout} gcloud projects get-iam-policy ${google_project.project.project_id} --format json)"
      current_iam_policy_bindings="$(echo $current_iam_policy | jq -c -r .bindings)"
      current_iam_policy_audit_configs="$(echo $current_iam_policy | jq -c -r -S .auditConfigs)"

      if [ "$(echo $expected_audit_configs | md5sum)" != "$(echo $current_iam_policy_audit_configs | md5sum)" ]; then
        jq -n -r \
          --argjson policy_audit_configs "$expected_audit_configs" \
          --argjson policy_bindings "$current_iam_policy_bindings" \
          '{"auditConfigs":$policy_audit_configs,"bindings":$policy_bindings}' > ${path.module}/${google_project.project.project_id}.iam.policy.json

        echo "Applying audit configs..."
        timeout -t ${var.gcloud_timeout} gcloud -q projects set-iam-policy ${google_project.project.project_id} ${path.module}/${google_project.project.project_id}.iam.policy.json

        rm ${path.module}/${google_project.project.project_id}.iam.policy.json
      else
        echo "Audit configs are up-to-date..."
      fi
    EOF
  }
}
