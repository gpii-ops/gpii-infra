# this Terraform module creates the same resources as project_init script and
# set the DNS zones structure.

terraform {
  backend "gcs" {}
}

variable "organization_name" {
  default = "gpii"
}

variable "organization_domain" {
  default = "gpii.net"
}

variable "project_name" {} # name of the project to create

# This variable set an owner account in addition to the service accounts needed
# to manage the project The format of this variable must match the argument
# reference for the members of the role:
# https://www.terraform.io/docs/providers/google/r/google_project_iam.html#argument-reference

# root projects: dev,stg and prd don't need a project_owner. They will use the
# IAMs inherited from the org.
#
# The variable is set to avoid a failure in the execution of the module, but it won't be set.

variable "project_owner" {
  default = ""
}

variable "billing_id" {}

variable "organization_id" {}

variable "serviceaccount_key" {}

# Id of the project which owns the credentials used by the provider
variable "project_id" {}

# the ci_dev_project_regex is a regular expression that matches the projects that will
# be excercised by the CI it will be ephemeral, with the same specs as any other
# developer project, except for the IAM permissions will be based on a service
# account in order to let the CI operate.

variable "ci_dev_project_regex" {
  default = "/^dev-doe$|^dev-gitlab-runner$/"
}

variable "service_apis" {
  default = [
    "bigquery-json.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "deploymentmanager.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "replicapool.googleapis.com",
    "replicapoolupdater.googleapis.com",
    "resourceviews.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-api.googleapis.com",
  ]
}

data "google_iam_policy" "combined" {
  binding {
    role = "roles/cloudkms.admin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/compute.admin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/container.clusterAdmin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/container.admin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/dns.admin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountKeyAdmin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/logging.configWriter"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/monitoring.editor"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/resourcemanager.projectIamAdmin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/serviceusage.serviceUsageAdmin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/storage.admin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/compute.serviceAgent"

    members = [
      "serviceAccount:service-${google_project.project.number}@compute-system.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/container.serviceAgent"

    members = [
      "serviceAccount:service-${google_project.project.number}@container-engine-robot.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/editor"

    members = [
      "serviceAccount:${google_project.project.number}-compute@developer.gserviceaccount.com",
      "serviceAccount:${google_project.project.number}@cloudservices.gserviceaccount.com",
      "serviceAccount:service-${google_project.project.number}@containerregistry.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/owner"

    members = [
      "${local.project_owners}",
    ]
  }

  audit_config {
    service = "allServices"

    audit_log_configs {
      log_type = "DATA_READ"
    }

    audit_log_configs {
      log_type = "DATA_WRITE"
    }

    audit_log_configs {
      log_type = "ADMIN_READ"
    }
  }
}

provider "google" {
  credentials = "${var.serviceaccount_key}"
  project     = "${var.project_id}"

  # Hardcoded region should be fixed in favor of TF_VAR_infra_region for consistency:
  # https://issues.gpii.net/browse/GPII-3707
  region = "us-central1"
}

# The dnsname and the dns domain must be computed for each new project created.
# The organization name may not match the organization domain.
locals {
  dnsname = "${replace(
              replace(
                google_project.project.name,
                "/([\\w]+)-([\\w]+)-([\\w]+)-?([-\\w]+)?/",
                "$4.$3.$2.${var.organization_domain}"),
              "/^\\./",
              "")
            }"

  # Service accounts will be empty list in case there's no google_service_account.project created
  # (this is instead of current `local.service_account` that is either actual account or empty)
  service_accounts = "${formatlist("serviceAccount:%s", google_service_account.project.*.email)}"

  # Project owners will be empty list if var.project_owner is empty string ""
  project_owners = "${compact(list(var.project_owner))}"

  # stg, prd, dev, and the projects that matches the ci_dev_project_regex variable are managed 
  # by the CI so they should have the service account and the permissions attached to it
  #
  root_project_iam = "${replace(var.project_name, var.ci_dev_project_regex, "") != "" && replace(var.project_name, "/^dev-.*/", "") == ""}"
}

resource "google_project" "project" {
  name            = "${var.organization_name}-gcp-${var.project_name}"
  project_id      = "${var.organization_name}-gcp-${var.project_name}"
  billing_account = "${var.billing_id}"
  org_id          = "${var.organization_id}"
}

resource "google_project_services" "project" {
  project  = "${google_project.project.project_id}"
  services = "${var.service_apis}"
}

resource "google_project_iam_policy" "project" {
  project     = "${google_project.project.project_id}"
  policy_data = "${data.google_iam_policy.combined.policy_data}"
}

resource "google_service_account" "project" {
  account_id   = "projectowner"
  display_name = "Project owner service account"
  project      = "${google_project.project.project_id}"
  count        = "${local.root_project_iam ? 0 : 1}"
}

resource "google_dns_managed_zone" "project" {
  project  = "${google_project.project.project_id}"
  name     = "${replace(local.dnsname, ".", "-")}"
  dns_name = "${local.dnsname}."

  depends_on = ["google_project_services.project",
    "google_project_iam_policy.project",
  ]
}

# Set the NS records in the parent zone of the parent project if the
# project_name has the pattern ${env}-${user}
resource "google_dns_record_set" "ns" {
  name         = "${local.dnsname}."
  managed_zone = "${element(split("-", var.project_name), 0)}-gcp-${replace(var.organization_domain, ".", "-")}"
  type         = "NS"
  ttl          = 3600
  project      = "${var.organization_name}-gcp-${element(split("-", var.project_name), 0)}"
  rrdatas      = ["${google_dns_managed_zone.project.name_servers}"]
  count        = "${replace(var.project_name, "/^dev-.*/", "") == "" ? 1 : 0}"
}

# Set the NS records in the gcp.$organization_domain zone of the
# $organization_name-gcp-common-$env if the project name doesn't have a hyphen.
resource "google_dns_record_set" "ns-root" {
  name         = "${local.dnsname}."
  managed_zone = "gcp-${replace(var.organization_domain, ".", "-")}"
  type         = "NS"
  ttl          = 3600
  project      = "${var.project_id}"
  rrdatas      = ["${google_dns_managed_zone.project.name_servers}"]
  count        = "${replace(var.project_name, "/^dev-.*/", "") == "" ? 0 : 1}"
}

resource "google_storage_bucket" "project-tfstate" {
  project = "${google_project.project.project_id}"
  name    = "${var.organization_name}-gcp-${var.project_name}-tfstate"

  versioning = {
    enabled = "true"
  }
}
