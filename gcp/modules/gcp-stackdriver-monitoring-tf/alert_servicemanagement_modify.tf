resource "google_monitoring_alert_policy" "servicemanagement_modify" {
  display_name = "Service management log does not contain API enabling / disabling events"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/servicemanagement.modify\" resource.type=\"audited_resource\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "0s"

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
        group_by_fields    = []
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "API enabling / disabling event found in the service management log"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&minLogLevel=0&expandAll=false&interval=PT1H&advancedFilter=resource.type%3D%22audited_resource%22%20AND%20protoPayload.serviceName%3D%22servicemanagement.googleapis.com%22%20AND%20(protoPayload.methodName%3D%22google.api.servicemanagement.v1.ServiceManager.DeactivateServices%22%20OR%20protoPayload.methodName%3D%22google.api.servicemanagement.v1.ServiceManager.ActivateServices%22%20OR%20protoPayload.methodName%3D%22google.api.servicemanagement.v1.ServiceManager.EnableService%22%20OR%20protoPayload.methodName%3D%22google.api.servicemanagement.v1.ServiceManager.DisableService%22)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"

  depends_on = ["google_logging_metric.servicemanagement_modify"]
}
