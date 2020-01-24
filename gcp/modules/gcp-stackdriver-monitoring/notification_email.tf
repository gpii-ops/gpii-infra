resource "google_monitoring_notification_channel" "email" {
  display_name = ""
  description  = ""
  type         = "email"

  labels = {
    email_address = "${(var.use_auth_user_email && var.auth_user_email != "") ? var.auth_user_email : var.notification_email}"
  }

  enabled = "true"
}
