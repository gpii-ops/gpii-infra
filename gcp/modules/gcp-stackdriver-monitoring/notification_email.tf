resource "google_monitoring_notification_channel" "email" {
  depends_on   = ["null_resource.destroy_old_stackdriver_resources"]
  display_name = ""
  description  = ""
  type         = "email"

  labels = {
    email_address = "${(var.use_auth_user_email && var.auth_user_email != "") ? var.auth_user_email : var.notification_email}"
  }

  enabled     = "true"
}
