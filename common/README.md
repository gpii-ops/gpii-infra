# Common gpii-infra GCP-AWS

This directory manages GPII infrastructure in [Google Cloud Project (GCP)](https://cloud.google.com/) and [Amazon Web Services (AWS)](https://aws.amazon.com/). It is organized as an [exekube](https://github.com/exekube/exekube) project and is very loosely based on the [exekube demo-apps-project](https://github.com/exekube/demo-apps-project)

Initial instructions based on [exekube's Getting Started](https://exekube.github.io/exekube/in-practice/getting-started/) (version 0.3.0).

## Setup

1. Clone this repo.
1. (Optional) Clone [the gpii-ops fork of exekube](https://github.com/gpii-ops/exekube).
   * The `gpii-infra` clone and the `exekube` clone should be siblings in the same directory (there are some references to `../exekube`).
1. `cd gpii-infra/common`
1. `alias xk='docker-compose run --rm --service-ports xk'`
1. `export ENV=prd`
1. You will need the `owner.json` file where the credentials are. You can copy
   the `gcp/live/(dev|prd)/secrets/` directory to `common/live/prd/`
1. Also the credentials of AWS are needed. They must be stored at
   `common/.config/prd/aws`
1. `export ORGANIZATION_ID=247149361674`
   * *OR* Create a GCP Free Trial account. Use the Organization ID from there.
1. `export BILLING_ID=01A0E1-B0B31F-349F4F`
   * *OR* Create a GCP Free Trial account. Use the Billing ID from there.
1. `export TF_VAR_project_id=xk-mrtyler`
   * The project ID must be unique across all of Google Cloud Platform, like an AWS S3 Bucket.
   * When changing to a new project\_id, I had to `rm .config/terragrunt`. This is something that `rake clean` should handle.
1. `xk gcloud auth login`
   * Follow the instructions to authenticate.
1. `xk gcp-project-init`
   * This step is not idempotent. It will fail if you've already initialized the project named in `$TF_VAR_project_id`.
1. `xk up live/dev/infra`
1. `xk up`

## Teardown

1. `xk down`
   * This is the important one since it shuts down the expensive bits (VMs in the Kubernetes cluster, mostly)
1. `xk down live/dev/infra`
   * Exekube recommends leaving these resources up since they are cheap
1. There's no automation for destroying the Project and starting over. I usually use the GCP Dashboard.
   * Note that "deleting" a Project really marks it for deletion in 30 days. You can't create a new Project with the same name until the old one is culled.

## One-time Google Cloud Account Setup
* https://cloud.google.com/resource-manager/docs/quickstart-organizations
   * G Suite: "The first time a user in your domain creates a project or billing account, the Organization resource is automatically created and linked to your company’s G Suite account. The current project and all future projects will automatically belong to the organization."
      * @mrtyler believes he did this when he created his Free Trial account using his RtF email address.
   * "If you're the Super Admin of your G Suite domain account, you can add yourself and others as the Organization Admin of the corresponding Organization. For instructions on adding Organization Admins, see Adding an organization admin."
* https://cloud.google.com/resource-manager/docs/creating-managing-organization#adding_an_organization_admin
   * Manually create IAMs for Ops Team. Assign role "Organization Policy Administrator" and "Billing Account User".
      * Actually this isn't working either -- even with admin privileges, Alfredo can't attach his Project to the Official Billing Account. Alfredo is investigating.
* https://cloud.google.com/resource-manager/docs/quickstart-organizations#create_a_billing_account
   * Manually create IAM for Eugene. Assign role "Billing Account Administrator".
   * Eugene creates Billing Account, "Official". Fills in contact info, payment info.
      * This Billing Account didn't show up for me until Eugene added me as billing admin for that billing account (even when I already had Organization Policy Administrator and Billing Account Administrator).
      * Giving myself Billing Account Administrator did allow me to see the Billing Account sgithens created for his Free Trial Account.
      * In spite of all those privileges, I can't Manage Payment Users for any Billing Accounts other than the one from my Free Trial Account.
   * Send billing emails to accounts-payable@rtf-us.org -- https://cloud.google.com/billing/docs/how-to/modify-contacts
      * Billing -> Official -> Payment Settings -> Payments Users -> Manage Payments Users -> Add a New User. Leave all Permissions unchecked. Leave Primary Contact unchecked (there can be only one, and it's Eugene). Confirm invitation email.
