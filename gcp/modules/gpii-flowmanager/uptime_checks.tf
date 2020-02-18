locals {
  uptime_checks = ["flowmanager"]
}

resource "google_monitoring_uptime_check_config" "this" {
  count        = "${length(local.uptime_checks)}"
  provider     = "google-beta"
  display_name = "${element(local.uptime_checks, count.index)}-https"
  timeout      = "10s"
  period       = "60s"

  http_check = {
    path    = "/health"
    port    = 443
    use_ssl = true
  }

  monitored_resource {
    type = "uptime_url"

    labels = {
      host       = "${element(local.uptime_checks, count.index)}.${var.domain_name}"
      project_id = "${var.project_id}"
    }
  }
}
