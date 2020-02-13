resource "google_monitoring_alert_policy" "iam_modify" {
  depends_on   = ["null_resource.wait_for_lbms"]
  display_name = "IAM audit logs do not contain policy modification events"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.iam_modify.name}\" resource.type=\"global\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "0s"

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
      }

      denominator_filter = ""
    }

    display_name = "IAM policy modification event found in audit logs"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&minLogLevel=0&expandAll=false&interval=PT1H&advancedFilter=(resource.type%3D%22project%22%20AND%20protoPayload.methodName%3D%22SetIamPolicy%22)%20OR%20(resource.type%3D%22service_account%22%20AND%20protoPayload.methodName:%22SetIAMPolicy%22))"
    mime_type = "text/markdown"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "true"
}
