resource "google_monitoring_notification_channel" "alerts_slack" {
  depends_on   = ["null_resource.destroy_old_stackdriver_resources"]
  count        = "${length(var.common_environments)}"
  type         = "slack"
  display_name = "Alerts ${element(var.common_environments, count.index)} Slack"

  labels = {
    channel_name = "#alerts-${element(var.common_environments, count.index)}"
    auth_token   = "${var.secret_slack_auth_token}"
  }

  user_labels = {}
  enabled     = "true"
}
