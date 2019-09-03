resource "google_monitoring_notification_channel" "alerts_stg_slack" {
  type = "slack"

  labels = {
    channel_name = "#alerts-stg"
  }

  user_labels = {}
  enabled     = "true"
}
