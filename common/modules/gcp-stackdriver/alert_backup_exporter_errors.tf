resource "google_monitoring_alert_policy" "backup_exporter_errors" {
  count        = "${length(var.common_environments)}"
  display_name = "Backup-exporter of ${element(var.common_environments, count.index)} snapshots are ok for 12 hours"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/backup-exporter.snapshot_created_${element(var.common_environments, count.index)}\" resource.type=\"k8s_container\""
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

    display_name = "Backup-exporter of ${element(var.common_environments, count.index)} snapshots are missing in the last 12 hours"
  }

  notification_channels = [
    "${google_monitoring_notification_channel.email.name}",
  ]

  user_labels = {}
  enabled     = true

  depends_on = ["google_logging_metric.backup_exporter_snapshot_created"]
}
