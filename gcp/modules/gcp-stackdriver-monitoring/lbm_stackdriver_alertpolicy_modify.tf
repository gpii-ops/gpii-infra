resource "google_logging_metric" "stackdriver_alertpolicy_modify" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "stackdriver.alertpolicy.modify"
  filter     = "protoPayload.serviceName=\"monitoring.googleapis.com\" AND (protoPayload.methodName:\"AlertPolicyService.DeleteAlertPolicy\" OR protoPayload.methodName:\"AlertPolicyService.UpdateAlertPolicy\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
