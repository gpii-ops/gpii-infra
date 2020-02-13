resource "google_monitoring_alert_policy" "couchdb_prometheus_exporter_exports_metric" {
  depends_on   = ["null_resource.wait_for_lbms"]
  display_name = "Pod `couchdb-prometheus-exporter` exports a metric"
  combiner     = "OR"
  project      = "${var.project_id}"

  conditions {
    condition_absent {
      filter   = "metric.type=\"custom.googleapis.com/couchdb/httpd_node_up\" resource.type=\"gke_container\""
      duration = "${(var.env == "prd" || var.env == "stg") ? "300" : "600"}s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_SUM"
      }
    }

    display_name = "Metric `custom/couchdb/httpd_node_up` is absent"
  }

  documentation = {
    content   = "This test verifies that metrics from couchdb are being exported by couchdb-prometheus-exporter and ingested by Stackdriver.\n\nIf this test fails in isolation, check the logs for couchdb-prometheus-exporter. (If couchdb itself is down, other tests are probably failing!)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]

  # Disabled on ephemeral clusters to avoid noise on recreation
  enabled = "${(var.env == "prd" || var.env == "stg") ? "true" : "false"}"
}
