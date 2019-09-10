resource "google_monitoring_notification_channel" "alerts_slack" {
  count        = "${(var.env == "prd" || var.env == "stg") ? 1 : 0}"
  type         = "slack"
  display_name = "Alerts #${var.env} Slack"

  labels = {
    channel_name = "#alerts-${var.env}"
  }

  user_labels = {}
  enabled     = "true"
}
