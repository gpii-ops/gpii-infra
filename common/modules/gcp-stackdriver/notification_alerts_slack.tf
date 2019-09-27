resource "google_monitoring_notification_channel" "alerts_slack_stg" {
  type         = "slack"
  display_name = "Alerts STG Slack"

  labels = {
    channel_name = "#alerts-stg"
  }

  user_labels = {}
  enabled     = "true"
}

resource "google_monitoring_notification_channel" "alerts_slack_prd" {
  type         = "slack"
  display_name = "Alerts PRD Slack"

  labels = {
    channel_name = "#alerts-prd"
  }

  user_labels = {}
  enabled     = "true"
}
