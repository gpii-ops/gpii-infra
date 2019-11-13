resource "google_monitoring_alert_policy" "ssl_cert_check" {
  display_name = "Flowmanager TLS cert is valid"
  combiner     = "OR"

  conditions {
    condition_threshold {
      filter          = "metric.type=\"custom.googleapis.com/ssl-cert-check/certificate_days_left\" AND resource.type=\"gke_container\" AND metric.labels.name=\"flowmanager.${var.domain_name}:443\""
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

      denominator_filter       = ""
      denominator_aggregations = []
    }

    display_name = "Flowmanager TLS cert is about to expire"
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}

resource "google_monitoring_alert_policy" "ssl_cert_check_absense" {
  display_name = "Flowmanager TLS cert metric is present"
  combiner     = "OR"

  conditions {
    condition_absent {
      filter   = "metric.type=\"custom.googleapis.com/ssl-cert-check/certificate_days_left\" AND resource.type=\"gke_container\" AND metric.labels.name=\"flowmanager.${var.domain_name}:443\""
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
  }

  notification_channels = ["${google_monitoring_notification_channel.email.name}", "${google_monitoring_notification_channel.alerts_slack.*.name}"]
  user_labels           = {}
  enabled               = "true"
}
