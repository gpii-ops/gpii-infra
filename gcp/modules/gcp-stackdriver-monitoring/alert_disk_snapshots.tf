data "external" "pvcs" {
  program = [
    "bash",
    "-c",
    "PVCS=$$(kubectl get --all-namespaces pvc --request-timeout 5s -o json | jq -cr \"[.items[].metadata.name] | join(\\\"|\\\")\"); jq -n --arg pvcs \"$$PVCS\" '{pvcs:$$pvcs}'",
  ]
}

resource "google_monitoring_alert_policy" "disk_snapshots" {
  display_name = "Snapshots are being created for all persistent volumes"
  combiner     = "OR"

  conditions = [
    {
      condition_absent {
        filter   = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\" AND metric.label.pv_name=monitoring.regex.full_match(\"pv-(${data.external.pvcs.result.pvcs})\") AND metric.label.severity=\"NOTICE\""
        duration = "600s"

        aggregations {
          alignment_period     = "600s"
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
        filter = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\" AND metric.label.pv_name=monitoring.regex.full_match(\"pv-(${data.external.pvcs.result.pvcs})\") AND metric.label.severity=\"NOTICE\""

        comparison      = "COMPARISON_LT"
        threshold_value = 1.0
        duration        = "600s"

        aggregations {
          alignment_period     = "600s"
          per_series_aligner   = "ALIGN_SUM"
          cross_series_reducer = "REDUCE_SUM"

          group_by_fields = [
            "metric.label.pv_name",
          ]
        }
      }

      display_name = "Snapshot creation events are occurring too infrequently for some persistent volumes"
    },
    {
      condition_threshold {
        filter = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\" AND metric.label.severity=\"ERROR\""

        aggregations {
          alignment_period   = "600s"
          per_series_aligner = "ALIGN_SUM"
        }

        denominator_filter = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\" AND metric.label.severity!=\"ERROR\""

        denominator_aggregations {
          alignment_period   = "600s"
          per_series_aligner = "ALIGN_SUM"
        }

        comparison      = "COMPARISON_GT"
        threshold_value = 0.05
        duration        = "0s"
      }

      display_name = "Error ratio exceeds 5% for events in snapshot creation audit log"
    },
  ]

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"

  depends_on = ["google_logging_metric.disks_createsnapshot"]
}
