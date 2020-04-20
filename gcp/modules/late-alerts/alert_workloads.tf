resource "google_monitoring_alert_policy" "k8s_workloads" {
  depends_on   = ["null_resource.wait_for_lbms"]
  display_name = "K8s Workloads"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\""
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }

      denominator_filter = ""
    }

    display_name = "Pod does not restart too often"
  }

  conditions {
    condition_threshold {
      filter             = "metric.type=\"custom.googleapis.com/kube-state-metrics/kube_deployment_status_replicas_available\" resource.type=\"gke_container\""
      denominator_filter = "metric.type=\"custom.googleapis.com/kube-state-metrics/kube_deployment_spec_replicas\" resource.type=\"gke_container\""
      comparison         = "COMPARISON_LT"
      threshold_value    = "0.6"
      duration           = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NONE"
      }

      denominator_aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NONE"
      }
    }

    display_name = "Deployment has enough available replicas"
  }

  conditions {
    condition_threshold {
      filter             = "metric.type=\"custom.googleapis.com/kube-state-metrics/kube_statefulset_status_replicas_ready\" resource.type=\"gke_container\""
      denominator_filter = "metric.type=\"custom.googleapis.com/kube-state-metrics/kube_statefulset_replicas\" resource.type=\"gke_container\""
      comparison         = "COMPARISON_LT"
      threshold_value    = "0.6"
      duration           = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NONE"
      }

      denominator_aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NONE"
      }
    }

    display_name = "StatefulSet has enough ready replicas"
  }

  notification_channels = [
    "${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}",
    "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}",
  ]

  enabled = "true"
}
