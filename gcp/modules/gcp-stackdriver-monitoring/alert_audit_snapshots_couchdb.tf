resource "google_monitoring_alert_policy" "k8s_snapshots_couchdb" {
  display_name = "Snapshots are being created for persistent volumes of CouchDB stateful set"
  combiner     = "OR"

  conditions = [{
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/audit.couchdb.snapshot_created\" resource.type=\"global\""
      duration = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
        group_by_fields    = []
      }
    }

    display_name = "Snapshot creation events are missing in audit logs of GCE snapshot"
  }
  ]

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "${(var.env == "prd" || var.env == "stg") ? true : false}"

  depends_on = ["google_logging_metric.audit_couchdb_snapshot_created"]
}
