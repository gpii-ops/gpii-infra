resource "google_monitoring_alert_policy" "cluster_resource_allocatable_utilization" {
  display_name = "K8s cluster allocatable resource utilization stays within 85% of capacity"
  combiner     = "OR"

  conditions = [
    {
      condition_threshold {
        filter          = "metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\" resource.type=\"k8s_node\""
        comparison      = "COMPARISON_GT"
        threshold_value = 0.85
        duration        = "180s"

        aggregations {
          alignment_period     = "60s"
          per_series_aligner   = "ALIGN_MEAN"
          cross_series_reducer = "REDUCE_MEAN"

          group_by_fields = [
            "resource.label.cluster_name",
          ]
        }

        denominator_filter       = ""
        denominator_aggregations = []
      }

      display_name = "K8s cluster allocated more than 85% of available CPU"
    },
    {
      condition_threshold {
        filter          = "metric.type=\"kubernetes.io/node/memory/allocatable_utilization\" resource.type=\"k8s_node\""
        comparison      = "COMPARISON_GT"
        threshold_value = 0.85
        duration        = "180s"

        aggregations {
          alignment_period     = "60s"
          per_series_aligner   = "ALIGN_MEAN"
          cross_series_reducer = "REDUCE_MEAN"

          group_by_fields = [
            "resource.label.cluster_name",
          ]
        }

        denominator_filter       = ""
        denominator_aggregations = []
      }

      display_name = "K8s cluster allocated more than 85% of available RAM"
    },
  ]

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}
