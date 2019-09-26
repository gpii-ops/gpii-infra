resource "google_monitoring_alert_policy" "stackdriver_alertpolicy_modify" {
  display_name = "Stackdriver audit log does not contain alert policy modification events"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/stackdriver.alertpolicy.modify\" resource.type=\"audited_resource\""
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

    display_name = "Alert policy modification event found in Stackdriver audit log"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&minLogLevel=0&expandAll=false&interval=PT1H&advancedFilter=protoPayload.serviceName%3D%22monitoring.googleapis.com%22%20AND%20(protoPayload.methodName:%22AlertPolicyService.DeleteAlertPolicy%22%20OR%20protoPayload.methodName:%22AlertPolicyService.UpdateAlertPolicy%22)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"

  depends_on = ["google_logging_metric.stackdriver_alertpolicy_modify"]
}
