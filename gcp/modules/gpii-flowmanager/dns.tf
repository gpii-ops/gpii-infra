data "terraform_remote_state" "network" {
  backend = "gcs"

  config {
    credentials    = "${var.serviceaccount_key}"
    bucket         = "${var.project_id}-tfstate"
    prefix         = "${var.env}/infra/network"
    encryption_key = "/dev/null"
  }
}

resource "google_dns_record_set" "flowmanager-dns" {
  name         = "flowmanager.${var.domain_name}."
  project      = "${var.project_id}"
  managed_zone = "${replace(var.domain_name, ".", "-")}"

  type    = "A"
  ttl     = 300
  rrdatas = ["${data.terraform_remote_state.network.static_ip_address}"]
}
