# One-time setup steps

This document describes manual steps needed for initial configuration when using gpii-infra with a public cloud provider for the first time.

## G Suite

* Create an Organizational Unit "Cloud Development Only"
   * From the [G Suite Admin Organizational Units page](https://admin.google.com/u/1/ac/orgunits), add a new Organizational Unit
* Disable unneeded G Suite Services
   * From the [G Suite Admin Apps page](https://admin.google.com/u/1/ac/appslist/core), select all Services, and select Off
   * From the [G Suite Admin Additional Services page](https://admin.google.com/u/1/ac/appslist/additional), select all Services **EXCEPT** "Groups for Business", and select Off
* Create a public Group "cloud-developers"
   * From the [G Suite Admin Groups page](https://admin.google.com/raisingthefloor.org/AdminHome?hl=en&fc=true#GroupList:), add a new Group
   * Set it so that anyone can view or post, but only Managers and Owners can invite members
   * Add "ops@" to the Group
* Create a Group "outage", for announcing public-facing outages
   * From the [G Suite Admin Groups page](https://admin.google.com/raisingthefloor.org/AdminHome?hl=en&fc=true#GroupList:), add a new Group
   * Set it to "Announce-only"
   * Add each member of "ops@" to the Group and make each a Manager
      * Admins must be Managers to post to this announce-only group, but Groups (like ops@) can't have elevated permissions

## Google Cloud Account

* https://cloud.google.com/resource-manager/docs/quickstart-organizations
   * G Suite: "The first time a user in your domain creates a project or billing account, the Organization resource is automatically created and linked to your company’s G Suite account. The current project and all future projects will automatically belong to the organization."
      * @mrtyler believes he did this when he created his Free Trial account using his RtF email address.
   * "If you're the Super Admin of your G Suite domain account, you can add yourself and others as the Organization Admin of the corresponding Organization. For instructions on adding Organization Admins, see Adding an organization admin."
* https://cloud.google.com/resource-manager/docs/creating-managing-organization#adding_an_organization_admin
   * Manually create IAMs for Ops Team. Assign role "Project -> Owner" and "Billing Account User".
* https://cloud.google.com/resource-manager/docs/quickstart-organizations#create_a_billing_account
   * Manually create IAM for Eugene. Assign role "Billing Account Administrator".
   * Eugene creates Billing Account, "Official". Fills in contact info, payment info.
      * This Billing Account didn't show up for me until Eugene added me as billing admin for that billing account (even when I already had Organization Policy Administrator and Billing Account Administrator).
      * Giving myself Billing Account Administrator did allow me to see the Billing Account sgithens created for his Free Trial Account.
      * In spite of all those privileges, I can't Manage Payment Users for any Billing Accounts other than the one from my Free Trial Account.
   * Send billing emails to accounts-payable@rtf-us.org -- https://cloud.google.com/billing/docs/how-to/modify-contacts
      * Billing -> Official -> Payment Settings -> Payments Users -> Manage Payments Users -> Add a New User. Leave all Permissions unchecked. Leave Primary Contact unchecked (there can be only one, and it's Eugene). Confirm invitation email.
* Remove default permissions assigned to any member of Organization
  * https://cloud.google.com/resource-manager/docs/access-control-org#viewing-access
    * Expand the role `Project Creator` and delete the record `raisingthefloor.org`
    * Expand the role `Billing Account Creator` and delete the record `raisingthefloor.org`
* https://support.google.com/code/contact/billing_quota_increase
   * @mrtyler requested a quota bump to 100 Projects.
      * He only authorized his own email for now, to see what it did. But it's possible other Ops team members will need to go through this step.
* When configuring additional organizations (i.e. test.gpii.net), it is important to grant common SA of target organization Billing Account User permissions on the organization that owns main billing account. This can be done by running `rake set_billing_org_perms` in target environment Terragrunt folder (`common/live/stg` in case of test.gpii.net), authenticated as member of cloud-admin group.

### Initial `common` infrastructure

See [common/README, Creating the initial infrastructure](https://github.com/gpii-ops/gpii-infra/blob/master/common/README.md#creating-the-initial-infrastructure).

## DNS

Until [GPII-2951](https://issues.gpii.net/browse/GPII-2951) is complete, we use Amazon Route53 for the RtF root domain and delegate all subdomains to Google DNS. The latter are managed in code; the former is not -- see [common/README, Importing existing resources](https://github.com/gpii-ops/gpii-infra/blob/master/common/README.md#importing-existing-resources) and [GPII-2883](https://issues.gpii.net/browse/GPII-2883) for details.

## Web security scans for an environment's public endpoints

To automatically scan publicly exposed endpointst for common vulnerabilities (XSS, Flash injection, HTTP in HTTPS, outdated/insecure libraries, etc):

1. Go to [Cloud Web Security Scanner](https://console.cloud.google.com/security/web-scanner/scanConfigs), you will be asked to select the project if needed.
1. Click "New Scan".
1. Enter endpoint URL into the "Name" field (e.g. `flowmanager.prd.gcp.gpii.net`).
1. As a "Starting URL" you can enter something like (replace `prd.gcp.gpii.net` with your environment's domain):
   * https://flowmanager.prd.gcp.gpii.net/health for Flowmanager endpoint.
1. You can add more URLs if needed using "Add a URL" link.
1. You can also exclude certain URLs from scanning if needed.
1. For long-lived environments:
   * Set "Schedule" to "Weekly".
   * Set "Next run" to any weekday of the following week.
   * Set "Export to Cloud Security Command Center" option to enable scan results propagation to Cloud Security Command Center findings (which will be reviewed by Ops team as part of [weekly infra metrics review](https://pad.gpii.net/mypads/?/mypads/group/gpii-infrastructure-standups-lix4njm/pad/view/key-metrics-for-infrastructure-pc1g4nnd)).
1. Click "Save".

## CI

See [CI-CD One-time setup steps](./CI-CD.md#one-time-setup-steps).

## Slack

1. RtF has a [Slack instance](https://raisingthefloor.slack.com). The Slackbot in #ops is manually configured with [`/remind`](https://get.slack.help/hc/en-us/articles/208423427-Setting-reminders) to tell the Ops team when it's time to perform certain key periodic functions (e.g. testing backups, testing the IR/DR Plan):
   * `/remind` commands must be entered one at a time. Check the output of `/remind list` to ensure each reminder has been understood separately, not as a single reminder containing a big block of text containing blank lines.
   * All times are US Mountain Time. You must adjust them to your Slack client's time zone (sorry, there is no way to specify time zone in `/remind`).
```
# End daily standup
/remind #ops to "end standup" at 11:00 every Monday
/remind #ops to "end standup" at 11:00 every Tuesday
/remind #ops to "end standup" at 11:00 every Wednesday
/remind #ops to "end standup" at 11:00 every Thursday
/remind #ops to "end standup" at 11:00 every Friday

# Before weekly
/remind #ops to "Add Ops Weekly agenda items to the Pad
https://pad.gpii.net/mypads/?/mypads/group/gpii-infrastructure-meetings-iqt4nbr/view
1. Anything to demo this week?
2. Review key metrics - https://pad.gpii.net/mypads/?/mypads/group/gpii-infrastructure-standups-lix4njm/pad/view/key-metrics-for-infrastructure-pc1g4nnd
2a. If you are on top of the Standup list, prepare a browser with all Key Metrics loaded and ready to review" at 10:05 every Monday

# Monthly backup test
/remind #ops to "Perform monthly backup restoration test, following instructions from https://github.com/gpii-ops/gpii-infra/blob/master/gcp/README.md#data-corruption-on-all-replicas-of-couchdb-cluster" at 10:05 on the 1st of every month

# Annual IR/DR Plan test
/remind #ops to "Test IR/DR Plan: https://docs.google.com/document/d/1LQHKsRdh8m4oAu-b3tz29cK5ggMv6bdueUa5s6Hyg_I/edit#heading=h.jvejvz2o01ns" at 10:05 on Sep 13 of every year
```
