terraform {
  backend "gcs" {}
}

variable "serviceaccount_key" {}

variable "project_id" {}

variable "infra_region" {}

# This variable contains the map of SAs for all users with access to the project.
# Format:
#   sa_name = "sa description"
variable "service_accounts" {
  type = "map"

  default = {
    projectowner                   = "CI service account"
    alfredo-at-raisingthefloor-org = "Service account for alfredo@raisingthefloor.org"
    tyler-at-raisingthefloor-org   = "Service account for tyler@raisingthefloor.org"
    sergey-at-raisingthefloor-org  = "Service account for sergey@raisingthefloor.org"
    stepan-at-raisingthefloor-org  = "Service account for stepan@raisingthefloor.org"
  }
}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"
  region      = "${var.infra_region}"
}

resource "google_service_account" "project" {
  count        = "${length(keys(var.service_accounts))}"
  account_id   = "${element(keys(var.service_accounts), count.index)}"
  display_name = "${element(values(var.service_accounts), count.index)}"
  project      = "${var.project_id}"
  count        = "${local.root_project_iam ? 0 : 1}"
}

output "admin_users" {
  value = "${formatlist("serviceAccount:%s", google_service_account.project.*.email)}"
}
