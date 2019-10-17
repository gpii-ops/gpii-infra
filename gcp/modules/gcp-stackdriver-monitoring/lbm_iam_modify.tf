resource "google_logging_metric" "iam_modify" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "iam.modify"
  filter     = "((resource.type=\"project\" AND protoPayload.methodName=\"SetIamPolicy\") OR (resource.type=\"service_account\" AND protoPayload.methodName:\"SetIAMPolicy\")) AND protoPayload.authenticationInfo.principalEmail!=\"projectowner@${var.common_project_id}.iam.gserviceaccount.com\" AND protoPayload.authenticationInfo.principalEmail!=\"${var.crm_sa}\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
