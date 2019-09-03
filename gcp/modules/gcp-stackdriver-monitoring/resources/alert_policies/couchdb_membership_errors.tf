resource "google_monitoring_alert_policy" "couchdb_membership_errors" {
  display_name = "CouchDB membership check logs do not contain errors"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/couchdb_membership.error\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1.0
      duration        = "0s"

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

    display_name = "K8s container restarting more often than 1.5 times per minute"
  }

  notification_channels = []
  user_labels           = {}
  enabled               = "true"
}
