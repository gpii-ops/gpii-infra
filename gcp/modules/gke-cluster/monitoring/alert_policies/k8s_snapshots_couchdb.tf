resource "google_monitoring_alert_policy" "k8s_snapshots_couchdb" {
  display_name = "Snapshots are being created for persistent volumes of CouchDB stateful set"
  combiner     = "OR"

  conditions = [{
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/k8s_snapshots.couchdb.snapshot_created\" resource.type=\"k8s_container\""
      duration = "300s"

      trigger {
        count   = 0
        percent = 0
      }

      aggregations {
        alignment_period     = "600s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_NONE"
        group_by_fields      = []
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "Snapshot creation events are missing in K8s-snapshot logs for CouchDB"
  },
    {
      condition_absent {
        filter   = "metric.type=\"logging.googleapis.com/user/compute.disks.createSnapshot\" resource.type=\"gce_disk\""
        duration = "300s"

        trigger {
          count   = 0
          percent = 0
        }

        aggregations {
          alignment_period     = "600s"
          per_series_aligner   = "ALIGN_SUM"
          cross_series_reducer = "REDUCE_NONE"
          group_by_fields      = []
        }

        denominator_filter       = ""
        denominator_aggregations = []
      }

      display_name = "Snapshot creation events are missing for CouchDB GCE disks"
    },
  ]

  notification_channels = []
  user_labels           = {}
  enabled               = "true"
}
