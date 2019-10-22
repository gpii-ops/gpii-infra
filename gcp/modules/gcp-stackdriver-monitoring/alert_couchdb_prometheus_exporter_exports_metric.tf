resource "google_monitoring_alert_policy" "couchdb_prometheus_exporter_exports_metric" {
  display_name = "Pod `couchdb-prometheus-exporter` exports a metric"
  combiner     = "OR"

  conditions {
    condition_absent {
      filter   = "metric.type=\"custom.googleapis.com/couchdb/httpd_node_up\" resource.type=\"gke_container\""
      duration = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = []
      }
    }

    display_name = "Metric `custom/couchdb/httpd_node_up` is absent"
  }

  documentation = {
    content   = "This test verifies that metrics from couchdb are being exported by couchdb-prometheus-exporter and ingested by Stackdriver.\n\nIf this test fails in isolation, check the logs for couchdb-prometheus-exporter. (If couchdb itself is down, other tests are probably failing!)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}
