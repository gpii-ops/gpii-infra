variable "nonce" {}

resource "google_monitoring_alert_policy" "dns_modify" {
  display_name = "CloudDNS audit log does not contain zone modification events"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/servicemanagement.modify\" resource.type=\"dns_managed_zone\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.0
      duration        = "0s"

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
        group_by_fields    = []
      }

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "Zone modification modification event found in CloudDNS audit log"
  }

  documentation = {
    content   = "[Use this link to explore policy events in Logs Viewer](https://console.cloud.google.com/logs/viewer?project=${var.project_id}&minLogLevel=0&expandAll=false&interval=PT1H&advancedFilter=resource.type%3D%22dns_managed_zone%22%20AND%20(protoPayload.methodName%3D%22dns.changes.create%22%20OR%20protoPayload.methodName%3D%22dns.managedZones.delete%22%20OR%20protoPayload.methodName%3D%22dns.managedZones.patch%22%20OR%20protoPayload.methodName%3D%22dns.managedZones.update%22)"
    mime_type = "text/markdown"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"

  depends_on = ["null_resource.wait_for_dns_modify_lbm"]
}

resource "null_resource" "wait_for_dns_modify_lbm" {
  depends_on = ["google_logging_metric.dns_modify"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = <<EOF
      COUNT=1
      MAX_RETRIES=60
      SLEEP_SEC=5
      ALERT_READY=false

      while [ "$ALERT_READY" != 'true' ] && [ "$COUNT" -le "$MAX_RETRIES" ]; do
        echo "Waiting for log based metric dns.modify to be ready ($COUNT/$MAX_RETRIES)"
        gcloud logging metrics describe dns.modify > /dev/null
        [ "$?" -eq 0 ] && ALERT_READY=true
        # Sleep only if we're not ready
        [ "$ALERT_READY" != 'true' ] && sleep "$SLEEP_SEC"
        COUNT=$((COUNT+1))
      done
    EOF
  }
}
