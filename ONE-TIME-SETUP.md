# One-time setup steps

This document describes manual steps needed for initial configuration when using gpii-infra with a public cloud provider for the first time.

## G Suite

* Create an Organizational Unit "Cloud Development Only"
   * From the [G Suite Admin Organizational Units page](https://admin.google.com/u/1/ac/orgunits), add a new Organizational Unit
* Disable unneeded G Suite Services
   * From the [G Suite Admin Apps page](https://admin.google.com/u/1/ac/appslist/core), select all Services, and select Off
   * From the [G Suite Admin Additional Services page](https://admin.google.com/u/1/ac/appslist/additional), select all Services **EXCEPT** Google Groups, and select Off
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
* https://support.google.com/code/contact/billing_quota_increase
   * @mrtyler requested a quota bump to 100 Projects.
      * He only authorized his own email for now, to see what it did. But it's possible other Ops team members will need to go through this step.

## CI

See [CI-CD One-time setup steps](./CI-CD.md#one-time-setup-steps).
