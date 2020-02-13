resource "google_monitoring_alert_policy" "cluster_resource_allocatable_utilization" {
  depends_on   = ["null_resource.wait_for_lbms"]
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

        denominator_filter = ""
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

        denominator_filter = ""
      }

      display_name = "K8s cluster allocated more than 85% of available RAM"
    },
  ]

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "true"
}
