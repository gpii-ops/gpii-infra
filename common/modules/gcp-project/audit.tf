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
      echo "Applying audit config..."

      auditConfigs=$(cat ${path.module}/resources/auditConfigs.json | jq -c -r .)
      bindings=$(gcloud projects get-iam-policy ${google_project.project.project_id} --format json | jq -c -r .bindings)

      jq -n -r \
        --argjson auditConfigs "$auditConfigs" \
        --argjson bindings "$bindings" \
        '{"auditConfigs":$auditConfigs,"bindings":$bindings}' > ${path.module}/${google_project.project.project_id}.iam.policy.json

      yes | gcloud projects set-iam-policy ${google_project.project.project_id} ${path.module}/${google_project.project.project_id}.iam.policy.json

      rm ${path.module}/${google_project.project.project_id}.iam.policy.json
    EOF
  }
}
