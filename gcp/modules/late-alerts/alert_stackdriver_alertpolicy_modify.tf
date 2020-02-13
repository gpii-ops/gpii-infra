resource "google_monitoring_alert_policy" "stackdriver_alertpolicy_modify" {
  depends_on   = ["null_resource.wait_for_lbms"]
  display_name = "Stackdriver audit log does not contain alert policy modification events"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.stackdriver_alertpolicy_modify.name}\" resource.type=\"audited_resource\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "0s"

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
      }

      denominator_filter = ""
    }

    display_name = "Alert policy modification event found in Stackdriver audit log"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&minLogLevel=0&expandAll=false&interval=PT1H&advancedFilter=protoPayload.serviceName%3D%22monitoring.googleapis.com%22%20AND%20(protoPayload.methodName:%22AlertPolicyService.DeleteAlertPolicy%22%20OR%20protoPayload.methodName:%22AlertPolicyService.UpdateAlertPolicy%22)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "true"
}
