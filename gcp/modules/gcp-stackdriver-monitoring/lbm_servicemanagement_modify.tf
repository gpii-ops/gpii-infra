resource "google_logging_metric" "servicemanagement_modify" {
  depends_on = ["null_resource.destroy_old_stackdriver_resources"]
  name       = "servicemanagement.modify"
  filter     = "resource.type=\"audited_resource\" AND protoPayload.serviceName=\"servicemanagement.googleapis.com\" AND (protoPayload.methodName=\"google.api.servicemanagement.v1.ServiceManager.DeactivateServices\" OR protoPayload.methodName=\"google.api.servicemanagement.v1.ServiceManager.ActivateServices\" OR protoPayload.methodName=\"google.api.servicemanagement.v1.ServiceManager.EnableService\" OR protoPayload.methodName=\"google.api.servicemanagement.v1.ServiceManager.DisableService\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
