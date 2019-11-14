resource "google_monitoring_notification_channel" "alerts_slack" {
  depends_on   = ["null_resource.destroy_old_stackdriver_resources"]
  count        = "${(var.env == "prd" || var.env == "stg") ? 1 : 0}"
  type         = "slack"
  display_name = "#alerts-${var.env}"

  labels = {
    channel_name = "#alerts-${var.env}"
    auth_token   = "${var.secret_slack_auth_token}"
  }

  user_labels = {}
  enabled     = "true"
}
