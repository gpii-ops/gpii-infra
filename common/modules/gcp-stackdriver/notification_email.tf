resource "google_monitoring_notification_channel" "email" {
  display_name = ""
  description  = ""
  type         = "email"

  labels = {
    email_address = "${var.notification_email}"
  }

  user_labels = {}
  enabled     = "true"
}
