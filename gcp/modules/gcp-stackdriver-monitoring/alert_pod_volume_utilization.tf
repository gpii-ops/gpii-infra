resource "google_monitoring_alert_policy" "pod_volume_utilization" {
  display_name = "K8s pods utilize less than 85% of persistent volume capacity"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/pod/volume/utilization\" resource.type=\"k8s_pod\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      duration        = "180s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      denominator_filter = ""
    }

    display_name = "K8s pod utilizes more than 85% of persistent volume capacity"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  enabled               = "true"
}
