resource "google_logging_metric" "stackdriver_alertpolicy_modify" {
  name   = "stackdriver.alertpolicy.modify"
  filter = "protoPayload.serviceName=\"monitoring.googleapis.com\" AND (protoPayload.methodName:\"AlertPolicyService.DeleteAlertPolicy\" OR protoPayload.methodName:\"AlertPolicyService.UpdateAlertPolicy\")"
}
