resource "google_monitoring_alert_policy" "k8s_snapshots_couchdb" {
  display_name = "Snapshots are being created for persistent volumes of CouchDB stateful set"
  combiner     = "OR"

  conditions = [{
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/k8s_snapshots.couchdb.snapshot_created\" resource.type=\"k8s_container\""
      duration = "300s"

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
        group_by_fields    = []
      }
    }

    display_name = "Snapshot creation events are missing in K8s-snapshot logs for CouchDB"
  },
    {
      condition_absent {
        filter   = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\""
        duration = "300s"

        aggregations {
          alignment_period   = "600s"
          per_series_aligner = "ALIGN_SUM"
          group_by_fields    = []
        }
      }

      display_name = "Snapshot creation events are missing for CouchDB GCE disks"
    },
  ]

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "false"

  depends_on = ["google_logging_metric.disks_createsnapshot", "google_logging_metric.k8s_snapshots_couchdb_snapshot_created"]
}
