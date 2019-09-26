resource "google_monitoring_alert_policy" "container_restart_rate" {
  display_name = "K8s containers does not restart more often than 1.5 times per minute"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1.5
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
        group_by_fields    = []
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "K8s container restarting more often than 1.5 times per minute"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}
