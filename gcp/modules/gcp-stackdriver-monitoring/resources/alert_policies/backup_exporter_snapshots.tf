resource "google_monitoring_alert_policy" "backup_exporter_snapshots" {
  display_name = "Backup-exporter process does not report one or more errors"
  combiner     = "OR"

  conditions {
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/backup-exporter.snapshot_created\" resource.type=\"k8s_container\""
      duration = "43200s"

      trigger {
        count   = 0
        percent = 0
      }

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

  notification_channels = []
  user_labels           = {}
  enabled               = "${(env == "prd" || env == "stg") ? true : false}"
}
