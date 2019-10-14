resource "google_monitoring_alert_policy" "backup_exporter_errors" {
  display_name = "Backup-exporter process does not report one or more errors"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/backup_exporter.error\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "900s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MAX"

        group_by_fields = [
          "metric.label.log",
        ]
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "Backup-exporter process reports one or more errors"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "${(var.env == "prd" || var.env == "stg") ? true : false}"

  depends_on = ["google_logging_metric.backup_exporter_error"]
}
