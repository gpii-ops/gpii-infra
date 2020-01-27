resource "google_monitoring_alert_policy" "couchdb_request_time" {
  depends_on = [
    "module.couchdb",
    "null_resource.couchdb_enable_pv_backups",
    "null_resource.couchdb_finish_cluster",
    "null_resource.wait_for_lbms",
  ]

  display_name = "CouchDB request time stays within 100ms"
  project      = "${var.project_id}"
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
      }

      denominator_filter = ""
    }

    display_name = "CouchDB request time exceeded 100ms"
  }

  documentation = {
    content   = "Typical \"healthy\" response time for CouchDB is < 50ms.\n\nThat value is doubled to give it some buffer and used as a threshold for this policy."
    mime_type = "text/markdown"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "true"
}
