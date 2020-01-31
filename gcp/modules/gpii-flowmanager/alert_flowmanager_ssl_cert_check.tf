resource "google_monitoring_alert_policy" "ssl_cert_check" {
  depends_on   = ["module.gpii-flowmanager"]
  display_name = "Flowmanager TLS cert is valid"
  combiner     = "OR"

  conditions = [
    {
      condition_threshold {
        filter          = "metric.type=\"custom.googleapis.com/ssl-cert-check/certificate_days_left\" AND resource.type=\"global\" AND metric.labels.name=\"flowmanager.${var.domain_name}:443\""
        comparison      = "COMPARISON_LT"
        threshold_value = 28.0
        duration        = "0s"

        aggregations {
          alignment_period     = "600s"
          per_series_aligner   = "ALIGN_MEAN"
          cross_series_reducer = "REDUCE_MIN"

          group_by_fields = [
            "metric.labels.name",
          ]
        }

        denominator_filter = ""
      }

      display_name = "Flowmanager TLS cert is about to expire"
    },
    {
      condition_absent {
        filter   = "metric.type=\"custom.googleapis.com/ssl-cert-check/certificate_days_left\" AND resource.type=\"global\" AND metric.labels.name=\"flowmanager.${var.domain_name}:443\""
        duration = "86400s"

        aggregations {
          alignment_period     = "600s"
          per_series_aligner   = "ALIGN_MEAN"
          cross_series_reducer = "REDUCE_MIN"

          group_by_fields = [
            "metric.labels.name",
          ]
        }
      }

      display_name = "Flowmanager TLS cert metric is absent"
    },
  ]

  notification_channels = ["${data.terraform_remote_state.alert_notification_channel.slack_notification_channel}", "${data.terraform_remote_state.alert_notification_channel.mail_notification_channel}"]
  enabled               = "true"
  count                 = "${(var.env == "prd" || var.env == "stg") ? 1 : 0}"
}
