resource "google_monitoring_alert_policy" "k8s_snapshots_couchdb" {
  display_name = "Snapshots are being created for persistent volumes of CouchDB stateful set"
  combiner     = "OR"

  conditions = [
    {
      condition_absent {
        filter   = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\""
        duration = "300s"

        aggregations {
          alignment_period   = "300s"
          per_series_aligner = "ALIGN_SUM"

          group_by_fields = [
            "resource.label.zone",
          ]
        }
      }

      display_name = "Snapshot creation events are missing for CouchDB GCE disks"
    },
    {
      condition_threshold {
        filter = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\""

        comparison      = "COMPARISON_LT"
        threshold_value = 1.0
        duration        = "300s"

        aggregations {
          alignment_period   = "300s"
          per_series_aligner = "ALIGN_SUM"

          group_by_fields = [
            "resource.label.zone",
          ]
        }
      }

      display_name = "Snapshot creation events are occuring too infrequently for CouchDB GCE disks"
    },
  ]

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}
