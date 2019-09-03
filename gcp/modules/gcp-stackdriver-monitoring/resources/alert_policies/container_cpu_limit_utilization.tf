resource "google_monitoring_alert_policy" "container_cpu_limit_utilization" {
  display_name = "K8s container CPU utilization stays within 85% of limit"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/container/cpu/limit_utilization\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      duration        = "180s"

      trigger {
        count   = 0
        percent = 0
      }

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_NONE"
        group_by_fields      = []
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "K8s container utilizes more than 85% of allowed CPU"
  }

  notification_channels = []
  user_labels           = {}
  enabled               = "true"
}
