resource "google_monitoring_alert_policy" "container_restart_rate" {
  depends_on   = ["null_resource.wait_for_lbms"]
  display_name = "K8s Workloads"
  combiner     = "OR"

  conditions = {
    condition_threshold = {
      filter          = "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      duration        = "300s"

      aggregations = {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }

      denominator_filter = ""
    }

    display_name = "Pod does not restart too often"
  }

  notification_channels = [
    "${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}",
    "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}",
  ]

  enabled = "true"
}
