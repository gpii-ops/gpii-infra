resource "google_monitoring_alert_policy" "flowmanager_uptime" {
  depends_on   = ["google_dns_record_set.flowmanager-dns"]
  display_name = "Uptime check on `flowmanager.${var.domain_name}` is green"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.label.host=\"flowmanager.${var.domain_name}\" AND resource.type=\"uptime_url\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1.0
      duration        = "${(var.env == "prd" || var.env == "stg") ? "300" : "600"}s"

      aggregations {
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"

        group_by_fields = [
          "resource.label.*",
        ]
      }

      denominator_filter = ""
    }

    display_name = "Uptime Check on flowmanager.${var.domain_name} is failing"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = true
}
