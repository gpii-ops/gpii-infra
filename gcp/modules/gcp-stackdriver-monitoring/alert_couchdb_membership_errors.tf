resource "google_monitoring_alert_policy" "couchdb_membership_errors" {
  display_name = "CouchDB membership check logs do not contain errors"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/couchdb_membership.error\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1.0
      duration        = "0s"

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
        group_by_fields    = []
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "Error found in CouchDB membership check logs"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&minLogLevel=0&expandAll=false&interval=PT1H&advancedFilter=resource.type%3D%22k8s_container%22%20AND%20resource.labels.container_name%3D%22couchdb-statefulset-assembler%22%20AND%20severity%3E%3D%22ERROR%22)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"

  depends_on = ["google_logging_metric.couchdb_membership_error"]
}
