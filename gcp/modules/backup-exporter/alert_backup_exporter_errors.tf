resource "google_monitoring_alert_policy" "backup_exporter_errors" {
  display_name = "Backup-exporter process does not report one or more errors"
  combiner     = "OR"
  depends_on   = ["null_resource.wait_for_lbms"]

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.backup_exporter_error.name}\" resource.type=\"k8s_container\""
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

      denominator_filter = ""
    }

    display_name = "Backup-exporter process reports one or more errors"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "${(var.env == "prd" || var.env == "stg") ? true : false}"
}
