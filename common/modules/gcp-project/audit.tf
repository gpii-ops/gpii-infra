variable "nonce" {}

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

      auditConfigs=$(echo '[${join(
        ",",
        formatlist(
          "{\"auditLogConfigs\":[{\"logType\":\"DATA_READ\"},{\"logType\":\"DATA_WRITE\"}],\"service\":\"%s\"}",
          concat(
            var.audited_project_apis,
            var.audited_apis
          )
        )
      )}]' | jq -c -r -S .)

      policy=$(gcloud projects get-iam-policy ${google_project.project.project_id} --format json)
      policy_bindings=$(echo $policy | jq -c -r .bindings)
      policy_auditConfigs=$(echo $policy | jq -c -r -S .auditConfigs)

      if [ "$(echo $auditConfigs | md5sum)" != "$(echo $policy_auditConfigs | md5sum)" ]; then
        jq -n -r \
          --argjson auditConfigs "$auditConfigs" \
          --argjson bindings "$policy_bindings" \
          '{"auditConfigs":$auditConfigs,"bindings":$bindings}' > ${path.module}/${google_project.project.project_id}.iam.policy.json

        echo "Applying audit configs..."
        gcloud -q projects set-iam-policy ${google_project.project.project_id} ${path.module}/${google_project.project.project_id}.iam.policy.json

        rm ${path.module}/${google_project.project.project_id}.iam.policy.json
      else
        echo "Audit configs are up-to-date..."
      fi
    EOF
  }
}
