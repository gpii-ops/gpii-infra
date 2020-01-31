resource "google_monitoring_alert_policy" "pod_exec" {
  depends_on   = ["null_resource.wait_for_lbms"]
  display_name = "K8s cluster API logs do not contain `kubectl exec` events"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.pods_exec_create.name}\" resource.type=\"k8s_cluster\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }

      denominator_filter = ""
    }

    display_name = "New `kubectl exec` event found in K8s API log"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&minLogLevel=0&expandAll=false&interval=PT1H&advancedFilter=resource.type%3D%22k8s_cluster%22%20AND%20protoPayload.methodName%3D%22io.k8s.core.v1.pods.exec.create%22%0A)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "true"
}
