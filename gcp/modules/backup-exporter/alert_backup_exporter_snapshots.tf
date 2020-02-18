resource "google_monitoring_alert_policy" "backup_exporter_snapshots" {
  display_name = "Backup-exporter snapshots are ok for 12 hours"
  combiner     = "OR"
  depends_on   = ["null_resource.wait_for_lbms"]

  conditions {
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.backup_exporter_snapshot_created.name}\" resource.type=\"k8s_container\""
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

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "${(var.env == "prd" || var.env == "stg") ? true : false}"
}
