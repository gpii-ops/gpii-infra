resource "google_monitoring_alert_policy" "couchdb_request_time" {
  display_name = "CouchDB request time stays within 100ms"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"custom.googleapis.com/couchdb/httpd_request_time\" resource.type=\"gke_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 100
      duration        = "180s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
        group_by_fields    = []
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "CouchDB request time exceeded 100ms"
  }

  documentation = {
    content   = "Typical \"healthy\" response time for CouchDB is < 50ms.\n\nThat value is doubled to give it some buffer and used as a threshold for this policy."
    mime_type = "text/markdown"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}
