resource "google_monitoring_notification_channel" "alerts_slack" {
  count        = "${length(var.common_environments)}"
  type         = "slack"
  display_name = "Alerts ${element(local.common_environments, count.index)} Slack"

  labels = {
    channel_name = "#alerts-${element(local.common_environments, count.index)}"
  }

  user_labels = {}
  enabled     = "true"
}
