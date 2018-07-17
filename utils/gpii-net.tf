### A ###


resource "google_dns_record_set" "a-api-ul-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "api.ul.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-build-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "build.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.35"
  ]
}

resource "google_dns_record_set" "a-ci--int-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "ci-int.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.22"
  ]
}

resource "google_dns_record_set" "a-ci--ws-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "ci-ws.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.22"
  ]
}

resource "google_dns_record_set" "a-ci-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "ci.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-easyone-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "easyone.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.39"
  ]
}

resource "google_dns_record_set" "a-flowmanager-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "flowmanager.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-get-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "get.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-gitlab-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "gitlab.gpii.net."
  type    = "A"
  ttl     = "300"
  rrdatas = [
    "205.211.169.66"
  ]
}

resource "google_dns_record_set" "a-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "71.13.162.139"
  ]
}

resource "google_dns_record_set" "a-issues-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "issues.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.38",
    "205.211.169.37"
  ]
}

resource "google_dns_record_set" "a-jenkins--internal-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "jenkins-internal.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "10.200.32.2"
  ]
}

resource "google_dns_record_set" "a-lists-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "lists.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-npgatheringtool-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "npgatheringtool.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.210"
  ]
}

resource "google_dns_record_set" "a-pad-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "pad.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-personabrowser-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "personabrowser.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "176.28.55.242"
  ]
}

resource "google_dns_record_set" "a-preferences-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "preferences.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-qi--backend-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "qi-backend.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-qi-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "qi.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-rbmm-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "rbmm.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-sat-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "sat.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.39"
  ]
}

resource "google_dns_record_set" "a-satdata-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "satdata.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.39"
  ]
}

resource "google_dns_record_set" "a-seizure-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "seizure.gpii.net."
  type    = "A"
  ttl     = "300"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-sst-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "sst.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.39"
  ]
}

resource "google_dns_record_set" "a-staging--flowmanager-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-flowmanager.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-staging--issues-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-issues.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-staging--preferences-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-preferences.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-staging--rbmm-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-rbmm.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.227"
  ]
}

resource "google_dns_record_set" "a-staging--secureflowmanager-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-secureflowmanager.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.227"
  ]
}

resource "google_dns_record_set" "a-staging--stmm-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-stmm.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.227"
  ]
}

resource "google_dns_record_set" "a-staging--terms-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-terms.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.227"
  ]
}

resource "google_dns_record_set" "a-staging--ul-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-ul.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.227"
  ]
}

resource "google_dns_record_set" "a-staging--wiki-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging-wiki.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.227"
  ]
}

resource "google_dns_record_set" "a-stmm-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "stmm.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-surveyserver-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "surveyserver.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "18.216.30.160"
  ]
}

resource "google_dns_record_set" "a-terms-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "terms.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

resource "google_dns_record_set" "a-tools-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "tools.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.39"
  ]
}

resource "google_dns_record_set" "a-wiki-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "wiki.gpii.net."
  type    = "A"
  ttl     = "3600"
  rrdatas = [
    "205.211.169.37",
    "205.211.169.38"
  ]
}

### CNAME ###


resource "google_dns_record_set" "cname-archive-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "archive.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-dev-developerspace-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "dev.developerspace.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-dev.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-dev-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "dev.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-dev.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-dev-saa-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "dev.saa.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-dev.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-developerspace-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "developerspace.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-ds-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "ds.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-ftp-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "ftp.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii.net."
  ]
}

resource "google_dns_record_set" "cname-metrics-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "metrics.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "6fc0765023c599b0c3e26479fe9c0895.us-east-1.aws.found.io"
  ]
}

resource "google_dns_record_set" "cname-pp-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "pp.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii.net."
  ]
}

resource "google_dns_record_set" "cname-preview-developerspace-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "preview.developerspace.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-preview-ds-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "preview.ds.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-preview-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "preview.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-preview-saa-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "preview.saa.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-preview-ul-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "preview.ul.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-saa-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "saa.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-staging-developerspace-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging.developerspace.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-stg.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-staging-ds-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging.ds.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-stg.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-staging-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-stg.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-staging-saa-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging.saa.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-stg.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-staging-ul-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "staging.ul.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-stg.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-testing-developerspace-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "testing.developerspace.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-testing-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "testing.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-testing-saa-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "testing.saa.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "golf.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-ul-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "ul.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-unifiedlisting-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "unifiedlisting.gpii.net."
  type    = "CNAME"
  ttl     = "300"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

resource "google_dns_record_set" "cname-www-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "www.gpii.net."
  type    = "CNAME"
  ttl     = "3600"
  rrdatas = [
    "gpii-prod.pushing7.com"
  ]
}

### TXT ###


resource "google_dns_record_set" "txt-_dmarc-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "_dmarc.gpii.net."
  type    = "TXT"
  ttl     = "300"
  rrdatas = [
    "\"v=DMARC1; p=none; rua=mailto:jdfltbui@ag.dmarcian.com;\""
  ]
}

resource "google_dns_record_set" "txt-ci-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "ci.gpii.net."
  type    = "TXT"
  ttl     = "300"
  rrdatas = [
    "\"v=spf1 a:i-0005.tor1.inclusivedesign.ca ~all\""
  ]
}

resource "google_dns_record_set" "txt-google-_domainkey-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "google._domainkey.gpii.net."
  type    = "TXT"
  ttl     = "300"
  rrdatas = [
    "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoO6MQriBI1fsY04U10xXTzDwdoiNGT/JF0byhbxsiUy3Gg3cl5ud0lBaAWEU4YnSwfGZpZVbZVVMDKyhZppOfEofAeUWosdgaQaRYlo5nuo7dHcwWBrdenQviJD7kANcgGxGq9BoJRIfjlrKSTa18eVAT2SrFoy634NfXit90J8M\" \"nmUm7oJdl7UXaj7p1/3xitvvqSIICojVPGmljWI00pxUIA2ttcDZOhNNbxou6NgKsIob/h9gx79XQkUHypubMYpZahkVCT5fofUHNX58nQi+nX7msxuMPxjAGred0vZT6VKIgLB7vp4dHd9zHDREPgA+PJXaX00iynrDe2RhjwIDAQAB\""
  ]
}

resource "google_dns_record_set" "txt-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "gpii.net."
  type    = "TXT"
  ttl     = "3600"
  rrdatas = [
    "\"v=spf1 include:_spf.google.com ~all\""
  ]
}

resource "google_dns_record_set" "txt-lists-gpii-net" {
  managed_zone = "${module.gcp_zone.gcp_name}"
  name    = "lists.gpii.net."
  type    = "TXT"
  ttl     = "300"
  rrdatas = [
    "\"v=spf1 a:i-0005.tor1.inclusivedesign.ca ~all\""
  ]
}

