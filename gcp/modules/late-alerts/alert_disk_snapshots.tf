locals {
  pv_name_regexp = "^pv-database-storage-couchdb-couchdb-[0-9]+$"
}

resource "google_monitoring_alert_policy" "disk_snapshots" {
  depends_on   = ["null_resource.wait_for_lbms"]
  display_name = "Snapshots are being created for all persistent volumes"
  combiner     = "OR"
  project      = "${var.project_id}"

  conditions = [
    {
      condition_absent {
        filter   = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.disks_createsnapshot.name}\" resource.type=\"gce_disk\" AND metric.label.pv_name=monitoring.regex.full_match(\"${local.pv_name_regexp}\") AND metric.label.severity=\"NOTICE\""
        duration = "600s"

        aggregations {
          alignment_period     = "300s"
          per_series_aligner   = "ALIGN_SUM"
          cross_series_reducer = "REDUCE_SUM"

          group_by_fields = [
            "metric.label.pv_name",
          ]
        }
      }

      display_name = "Snapshot creation events are missing for some persistent volumes"
    },
    {
      condition_threshold {
        filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.disks_createsnapshot.name}\" resource.type=\"gce_disk\" AND metric.label.pv_name=monitoring.regex.full_match(\"${local.pv_name_regexp}\") AND metric.label.severity=\"NOTICE\""

        comparison      = "COMPARISON_LT"
        threshold_value = 1.0
        duration        = "600s"

        aggregations {
          alignment_period     = "300s"
          per_series_aligner   = "ALIGN_SUM"
          cross_series_reducer = "REDUCE_SUM"

          group_by_fields = [
            "metric.label.pv_name",
          ]
        }
      }

      display_name = "Snapshot creation events are occurring too infrequently for some persistent volumes"
    },
  ]

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]

  # Disabled on ephemeral clusters to avoid noise on recreation
  enabled = "${(var.env == "prd" || var.env == "stg") ? "true" : "false"}"
}
