resource "google_monitoring_notification_channel" "email" {
  display_name = ""
  description  = ""
  type         = "email"

  labels = {
    email_address = "${notification_email}"
  }

  user_labels         = {}
  verification_status = "VERIFICATION_STATUS_UNSPECIFIED"
  enabled             = "true"
}
