# Common gpii-infra GCP-AWS

This directory manages GPII infrastructure in [Google Cloud Project (GCP)](https://cloud.google.com/) and [Amazon Web Services (AWS)](https://aws.amazon.com/). It is organized as an [exekube](https://github.com/exekube/exekube) project and is very loosely based on the [exekube demo-apps-project](https://github.com/exekube/demo-apps-project)

Initial instructions based on [exekube's Getting Started](https://exekube.github.io/exekube/in-practice/getting-started/) (version 0.3.0).

## Project structure

The project structure is like following:

- gpii-common-prd (only for creating the rest of the infrastructure)
- gpii-gcp-prd
- gpii-gcp-stg
- gpii-gcp-dev
- gpii-gcp-dev-${user}

Each project will have the IAMs needed to create the GPII infrastructure inside as an Exekube individual project.

Also each project is meant to be managed by its own Terraform code, and also it will have its own tfstate file.

The DNS is the trickiest part, because each subdomain needs a NS record in the parent domain.

The DNS zones are:

- gpii.net
- gcp.gpii.net
- prd.gcp.gpii.net
- stg.gcp.gpii.net
- dev.gcp.gpii.net
- ${user}.dev.gcp.gpii.net

## Creating the initial infrastructure

1. Clone this repo.
1. (Optional) Clone [the gpii-ops fork of exekube](https://github.com/gpii-ops/exekube).
   * The `gpii-infra` clone and the `exekube` clone should be siblings in the same directory (there are some references to `../exekube`).
1. By default you'll use the RtF Organization and Billing Account.
   * You can use a different Organization or Billing Account, e.g. from a GCP Free Trial Account, with `export ORGANIZATION_ID=111111111111` and/or `export BILLING_ID=222222-222222-222222`.
1. Check that [you have the AWS credentials](../aws#configure-cloud-provider-credentials).
1. `cd gpii-infra/common/live/prd`
1. `rake auth`
   * This will give you a link to initiate the authentication process. Go to that link, use your Google account and paste back the token given.
1. `rake infra_init`
   * This will create a project called `gpii-common-prd`, with all the resources needed to run Terraform and create all the organization projects.
   * This step must be executed by an user with admin privileges in the organization, because it needs to create IAMs that are able to create projects and associate the billing account to them.
1. `rake project_init`
   * This will set the credentials and the default project needed for the next step
1. `rake apply_projects`
   * This will create all the projects in the organization. Each project is defined by the content of a directory in `common/live/prd/infra`
