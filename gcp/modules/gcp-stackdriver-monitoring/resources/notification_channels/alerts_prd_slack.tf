resource "google_monitoring_notification_channel" "alerts_prd_slack" {
  type = "slack"

  labels = {
    channel_name = "#alerts-prd"
  }

  user_labels = {}
  enabled     = "true"
}
