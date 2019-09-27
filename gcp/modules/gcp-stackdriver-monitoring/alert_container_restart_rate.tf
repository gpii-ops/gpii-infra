resource "google_monitoring_alert_policy" "container_restart_rate" {
  display_name = "K8s containers does not restart more often than 2 times per minute in 5 min"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 2
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_DELTA"

        group_by_fields = [
          "resource.label.container_name",
        ]
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "K8s container is restarting more often than 2 times per minute during 5 min"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}
