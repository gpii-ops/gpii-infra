resource "google_monitoring_alert_policy" "backup_exporter_errors_stg" {
  display_name = "Backup-exporter of stg snapshots are ok for 12 hours"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/backup-exporter.snapshot_created_stg\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "43200s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_MAX"

        group_by_fields = [
          "metric.label.log",
        ]
      }
    }

    display_name = "Backup-exporter of stg snapshots are missing in the last 12 hours"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack_stg.name}"]
  user_labels           = {}
  enabled               = "${(var.env == "prd" || var.env == "stg") ? true : false}"

  depends_on = ["google_logging_metric.backup-exporter_snapshot_created_stg"]
}

resource "google_monitoring_alert_policy" "backup_exporter_errors_prd" {
  display_name = "Backup-exporter of prd snapshots are ok for 12 hours"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/backup-exporter.snapshot_created_prd\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "43200s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_MAX"

        group_by_fields = [
          "metric.label.log",
        ]
      }
    }

    display_name = "Backup-exporter of prd snapshots are missing in the last 12 hours"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack_prd.name}"]
  user_labels           = {}
  enabled               = "${(var.env == "prd" || var.env == "stg") ? true : false}"

  depends_on = ["google_logging_metric.backup-exporter_snapshot_created_prd"]
}
