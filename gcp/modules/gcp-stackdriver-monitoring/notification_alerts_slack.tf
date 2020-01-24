resource "google_monitoring_notification_channel" "alerts_slack" {
  count        = "${(var.env == "prd" || var.env == "stg") ? 1 : 0}"
  type         = "slack"
  display_name = "#alerts-${var.env}"

  labels = {
    channel_name = "#alerts-${var.env}"
    auth_token   = "${var.secret_slack_auth_token}"
  }

  enabled = "true"
}

output "slack_notification_channel" {
  value = "${google_monitoring_notification_channel.alerts_slack.*.name}"
}

output "mail_notification_channel" {
  value = "${google_monitoring_notification_channel.email.name}"
}
