resource "google_monitoring_alert_policy" "backup_exporter_snapshots" {
  display_name = "Backup-exporter snapshots are ok for 12 hours"
  combiner     = "OR"
  depends_on   = ["google_logging_metric.backup_exporter_snapshot_created"]

  conditions {
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/backup_exporter.snapshot_created\" resource.type=\"k8s_container\""
      duration = "43200s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_MAX"

        group_by_fields = [
          "metric.label.log",
        ]
      }
    }

    display_name = "Backup-exporter snapshots failed in less than 12 hours"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "${(var.env == "prd" || var.env == "stg") ? true : false}"

  depends_on = ["google_logging_metric.backup_exporter_snapshot_created"]
}
