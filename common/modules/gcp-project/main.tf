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

variable "stg_log_viewers" {
  default = "group:web-developers@raisingthefloor.org"
}

# Id of the project which owns the credentials used by the provider
variable "project_id" {}

variable "infra_region" {}

# the ci_dev_project_regex is a regular expression that matches the projects that will
# be excercised by the CI it will be ephemeral, with the same specs as any other
# developer project, except for the IAM permissions will be based on a service
# account in order to let the CI operate.

variable "ci_dev_project_regex" {
  default = "/^dev-doe$|^dev-gitlab-runner$/"
}

variable "service_apis" {
  default = [
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "containeranalysis.googleapis.com",
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
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sourcerepo.googleapis.com",
    "stackdriver.googleapis.com",
    "storage-api.googleapis.com",
    "websecurityscanner.googleapis.com",
  ]
}

data "google_iam_policy" "combined" {
  binding {
    role = "roles/binaryauthorization.serviceAgent"

    members = [
      "serviceAccount:service-${google_project.project.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/binaryauthorization.policyAdmin"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_bin_auth.email}",
    ]
  }

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
      "serviceAccount:${google_project.project.number}@cloudbuild.gserviceaccount.com",
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
    role = "roles/containeranalysis.ServiceAgent"

    members = [
      "serviceAccount:service-${google_project.project.number}@container-analysis.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/dns.admin"

    members = [
      "${local.service_accounts}",
      "serviceAccount:${google_service_account.gke_cluster_pod_cert_manager.email}",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountKeyAdmin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "${local.service_accounts}",
      "serviceAccount:${google_project.project.number}@cloudbuild.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountActor"

    members = [
      "serviceAccount:${google_project.project.number}@cloudbuild.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "serviceAccount:${google_project.project.number}@cloudbuild.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/iam.serviceAccountAdmin"

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
    role = "roles/cloudbuild.builds.builder"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
      "serviceAccount:${google_project.project.number}@cloudbuild.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudbuild.builds.editor"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
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
      "serviceAccount:${google_project.project.number}@cloudservices.gserviceaccount.com",
      "serviceAccount:service-${google_project.project.number}@containerregistry.iam.gserviceaccount.com",
    ]
  }

  # Google IAM requires a special "invite" workflow for the Owner
  # role when the account is not part of the Organization. This
  # comes up when using user@rtf named accounts in the test
  # Organization. The error might (unhelpfully) look like this,
  # followed by a bunch of Go structs:
  #
  # googleapi: Error 400: Request contains an invalid argument., badRequest
  binding {
    role = "roles/owner"

    members = [
      "${local.project_owners}",
    ]
  }

  # Needed so that ADCs can impersonate the dedicated binary auth SA. See
  # GPII-3860.
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "${local.project_owners}",
    ]
  }

  # Needed for setting up monitoring
  # GPII-2782
  binding {
    role = "roles/logging.configWriter"

    members = [
      "${local.service_accounts}",
    ]
  }

  # Needed for setting up monitoring
  # GPII-2782
  binding {
    role = "roles/monitoring.alertPolicyEditor"

    members = [
      "${local.service_accounts}",
    ]
  }

  # Needed for setting up monitoring
  # GPII-2782
  binding {
    role = "roles/monitoring.notificationChannelEditor"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/logging.viewer"

    members = [
      "${local.stg_log_viewers}",
    ]
  }

  binding {
    role = "roles/logging.logWriter"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_node.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_default.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
    ]
  }

  binding {
    role = "roles/monitoring.metricWriter"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_node.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_default.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_cert_manager.email}",
    ]
  }

  binding {
    role = "roles/monitoring.viewer"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_node.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_default.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_cert_manager.email}",
    ]
  }

  binding {
    role = "roles/websecurityscanner.serviceAgent"

    members = [
      "serviceAccount:service-${google_project.project.number}@gcp-sa-websecurityscanner.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudtrace.agent"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_node.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_default.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
    ]
  }

  binding {
    role = "roles/sourcerepo.serviceAgent"

    members = [
      "serviceAccount:service-${google_project.project.number}@sourcerepo-service-accounts.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/compute.storageAdmin"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_pod_k8s_snapshots.email}",
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
    ]
  }

  binding {
    role = "roles/compute.viewer"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
    ]
  }

  binding {
    role = "roles/iam.roleViewer"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
    ]
  }

  binding {
    role = "roles/serviceusage.serviceUsageConsumer"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
    ]
  }

  binding {
    role = "roles/storage.objectViewer"

    members = [
      "serviceAccount:${google_service_account.gke_cluster_pod_backup_exporter.email}",
    ]
  }

  # Permissions below should be removed once the ticket is closed.
  # More info: https://issues.gpii.net/browse/GPII-4158
  binding {
    role = "roles/bigquery.admin"

    members = [
      "${local.service_accounts}",
    ]
  }

  binding {
    role = "roles/bigquery.dataEditor"

    members = [
      "serviceAccount:cloud-logs@system.gserviceaccount.com",
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
  region      = "${var.infra_region}"
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

  # Groups that can see the logs in staging.
  stg_log_viewers = "${compact(list(var.project_name == "stg" ? var.stg_log_viewers : ""))}"

  # stg, prd, dev, and the projects that matches the ci_dev_project_regex variable are managed
  # by the CI so they should have the service account and the permissions attached to it
  #
  root_project_iam = "${replace(var.project_name, var.ci_dev_project_regex, "") != "" && replace(var.project_name, "/^dev-.*/", "") == ""}"
}

resource "google_project" "project" {
  name                = "${var.organization_name}-gcp-${var.project_name}"
  project_id          = "${var.organization_name}-gcp-${var.project_name}"
  billing_account     = "${var.billing_id}"
  org_id              = "${var.organization_id}"
  auto_create_network = false
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

# Override NS record created by google_dns_managed_zone
# to set proper TTL
resource "google_dns_record_set" "project" {
  name         = "${local.dnsname}."
  managed_zone = "${google_dns_managed_zone.project.name}"
  type         = "NS"
  ttl          = 3600
  project      = "${google_project.project.project_id}"
  rrdatas      = ["${google_dns_managed_zone.project.name_servers}"]
  depends_on   = ["google_dns_managed_zone.project"]
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

  # Default region "US" should be fixed in favor of TF_VAR_infra_region for consistency:
  # https://issues.gpii.net/browse/GPII-3707
  # location = "${var.infra_region}"
  location = "US"

  force_destroy = false

  versioning = {
    enabled = "true"
  }
}
