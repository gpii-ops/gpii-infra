### A ###

resource "google_dns_record_set" "a-api-ul-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "api.ul.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-build-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "build.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.35",
  ]
}

resource "google_dns_record_set" "a-ci--int-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "ci-int.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.22",
  ]
}

resource "google_dns_record_set" "a-ci--ws-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "ci-ws.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.22",
  ]
}

resource "google_dns_record_set" "a-ci-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "ci.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-easyone-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "easyone.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.39",
  ]
}

resource "google_dns_record_set" "a-flowmanager-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "flowmanager.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-get-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "get.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-gitlab-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "gitlab.gpii.net."
  type         = "A"
  ttl          = "300"

  rrdatas = [
    "205.211.169.66",
  ]
}

resource "google_dns_record_set" "a-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "71.13.162.139",
  ]
}

resource "google_dns_record_set" "a-issues-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "issues.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.38",
    "205.211.169.37",
  ]
}

resource "google_dns_record_set" "a-jenkins--internal-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "jenkins-internal.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "10.200.32.2",
  ]
}

resource "google_dns_record_set" "a-lists-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "lists.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-npgatheringtool-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "npgatheringtool.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.210",
  ]
}

resource "google_dns_record_set" "a-pad-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "pad.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-personabrowser-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "personabrowser.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "176.28.55.242",
  ]
}

resource "google_dns_record_set" "a-preferences-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "preferences.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-qi--backend-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "qi-backend.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-qi-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "qi.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-rbmm-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "rbmm.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-sat-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "sat.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.39",
  ]
}

resource "google_dns_record_set" "a-satdata-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "satdata.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.39",
  ]
}

resource "google_dns_record_set" "a-seizure-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "seizure.gpii.net."
  type         = "A"
  ttl          = "300"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-sst-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "sst.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.39",
  ]
}

resource "google_dns_record_set" "a-staging--flowmanager-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-flowmanager.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-staging--issues-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-issues.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-staging--preferences-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-preferences.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-staging--rbmm-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-rbmm.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.227",
  ]
}

resource "google_dns_record_set" "a-staging--secureflowmanager-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-secureflowmanager.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.227",
  ]
}

resource "google_dns_record_set" "a-staging--stmm-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-stmm.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.227",
  ]
}

resource "google_dns_record_set" "a-staging--terms-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-terms.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.227",
  ]
}

resource "google_dns_record_set" "a-staging--ul-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-ul.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.227",
  ]
}

resource "google_dns_record_set" "a-staging--wiki-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging-wiki.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.227",
  ]
}

resource "google_dns_record_set" "a-stmm-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "stmm.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-surveyserver-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "surveyserver.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "18.216.30.160",
  ]
}

resource "google_dns_record_set" "a-terms-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "terms.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.37",
    "205.211.169.38",
  ]
}

resource "google_dns_record_set" "a-tools-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "tools.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.39",
  ]
}

resource "google_dns_record_set" "a-wiki-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "wiki.gpii.net."
  type         = "A"
  ttl          = "3600"

  rrdatas = [
    "205.211.169.38",
    "205.211.169.37",
  ]
}

### CNAME ###

resource "google_dns_record_set" "cname-dev-developerspace-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "dev.developerspace.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-dev.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-dev-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "dev.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-dev.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-dev-saa-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "dev.saa.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-dev.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-developerspace-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "developerspace.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-ds-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "ds.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-ftp-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "ftp.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii.net.",
  ]
}

resource "google_dns_record_set" "cname-metrics-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "metrics.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "6fc0765023c599b0c3e26479fe9c0895.us-east-1.aws.found.io.",
  ]
}

resource "google_dns_record_set" "cname-pp-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "pp.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii.net.",
  ]
}

resource "google_dns_record_set" "cname-preview-developerspace-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "preview.developerspace.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-preview-ds-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "preview.ds.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-preview-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "preview.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-preview-saa-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "preview.saa.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-preview-ul-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "preview.ul.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-saa-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "saa.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-staging-developerspace-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging.developerspace.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-stg.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-staging-ds-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging.ds.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-stg.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-staging-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-stg.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-staging-saa-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging.saa.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-stg.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-staging-ul-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "staging.ul.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-stg.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-survey-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "survey.gpii.net."
  type         = "CNAME"
  ttl          = "300"

  rrdatas = [
    "gpii-ops.github.io.",
  ]
}

resource "google_dns_record_set" "cname-testing-developerspace-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "testing.developerspace.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-testing-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "testing.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-testing-saa-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "testing.saa.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "golf.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-ul-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "ul.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-unifiedlisting-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "unifiedlisting.gpii.net."
  type         = "CNAME"
  ttl          = "300"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

resource "google_dns_record_set" "cname-www-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "www.gpii.net."
  type         = "CNAME"
  ttl          = "3600"

  rrdatas = [
    "gpii-prod.pushing7.com.",
  ]
}

### TXT ###

resource "google_dns_record_set" "txt-_dmarc-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "_dmarc.gpii.net."
  type         = "TXT"
  ttl          = "300"

  rrdatas = [
    "\"v=DMARC1; p=none; rua=mailto:jdfltbui@ag.dmarcian.com;\"",
  ]
}

resource "google_dns_record_set" "txt-ci-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "ci.gpii.net."
  type         = "TXT"
  ttl          = "300"

  rrdatas = [
    "\"v=spf1 a:i-0005.tor1.incd.ca ~all\"",
  ]
}

resource "google_dns_record_set" "txt-google-_domainkey-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "google._domainkey.gpii.net."
  type         = "TXT"
  ttl          = "300"

  rrdatas = [
    "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoO6MQriBI1fsY04U10xXTzDwdoiNGT/JF0byhbxsiUy3Gg3cl5ud0lBaAWEU4YnSwfGZpZVbZVVMDKyhZppOfEofAeUWosdgaQaRYlo5nuo7dHcwWBrdenQviJD7kANcgGxGq9BoJRIfjlrKSTa18eVAT2SrFoy634NfXit90J8M\" \"nmUm7oJdl7UXaj7p1/3xitvvqSIICojVPGmljWI00pxUIA2ttcDZOhNNbxou6NgKsIob/h9gx79XQkUHypubMYpZahkVCT5fofUHNX58nQi+nX7msxuMPxjAGred0vZT6VKIgLB7vp4dHd9zHDREPgA+PJXaX00iynrDe2RhjwIDAQAB\"",
  ]
}

resource "google_dns_record_set" "txt-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "gpii.net."
  type         = "TXT"
  ttl          = "3600"

  rrdatas = [
    "\"github-verification=5m8KbkVQdz3tA5U77YdQqBzZ3XuQJDjATzfRvkHH\"",
    "\"v=spf1 include:_spf.google.com ~all\"",
  ]
}

resource "google_dns_record_set" "txt-lists-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "lists.gpii.net."
  type         = "TXT"
  ttl          = "300"

  rrdatas = [
    "\"v=spf1 a:i-0005.tor1.incd.ca ~all\"",
  ]
}

resource "google_dns_record_set" "txt-test-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "test.gpii.net."
  type         = "TXT"
  ttl          = "300"

  rrdatas = [
    "\"google-site-verification=t52ERdrOu7-_ZRE58am48DhsOIQhpx4MwCGCHl7_LeI\"",
  ]
}

resource "google_dns_record_set" "mx-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "gpii.net."
  type         = "MX"
  ttl          = 3600

  rrdatas = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com.",
  ]
}

resource "google_dns_record_set" "mx-lists-gpii-net" {
  count        = "${replace(var.organization_domain, "/^gpii.net/", "") == "" ? 1 : 0}"
  managed_zone = "${google_dns_managed_zone.root_zone.name}"
  name         = "lists.gpii.net."
  type         = "MX"
  ttl          = 3600

  rrdatas = [
    "10 lists-gpii-net.p10.spamhero.com.",
    "20 lists-gpii-net.p20.spamhero.net.",
    "30 lists-gpii-net.p30.spamhero.net.",
    "40 lists-gpii-net.p40.spamhero.net.",
  ]
}
