# Common gpii-infra GCP

This directory manages GPII infrastructure in [Google Cloud Project (GCP)](https://cloud.google.com/). It is organized as an [exekube](https://github.com/exekube/exekube) project and is very loosely based on the [exekube demo-apps-project](https://github.com/exekube/demo-apps-project)

Initial instructions based on [exekube's Getting Started](https://exekube.github.io/exekube/in-practice/getting-started/) (version 0.3.0).

## Project structure

The project structure is like following:

- gpii-common-prd (only for creating the rest of the infrastructure)
- gpii-common-stg (see [Testing the gpii-infra common](#testing-the-gpii-infra-common))
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

The zones "gpii.net", "gcp.gpii.net", "test.gpii.net" and "gcp.test.gpii.net" need to be created manually before this code creates the rest of the resources.

This code will use the following zones stored in the following projects:

* DNS: "gcp.gpii.net"
* id: gcp-gpii-net
* project: gpii-common-prd

* DNS: "gcp.test.gpii.net"
* id: gcp-test-gpii-net
* project: gpii2test-common-prd (testing organization)

## Creating the initial infrastructure

1. Clone this repo.
1. (Optional) Clone [the gpii-ops fork of exekube](https://github.com/gpii-ops/exekube).
   * The `gpii-infra` clone and the `exekube` clone should be siblings in the same directory (there are some references to `../exekube`).
1. By default you'll use the RtF Organization and Billing Account.
   * You can use a different Organization or Billing Account, e.g. from a GCP Free Trial Account, with `export ORGANIZATION_ID=111111111111` and/or `export BILLING_ID=222222-222222-222222`.
1. `rake apply_common_infra`
   * This will create a project called `gpii-common-prd` or `gpii-common-stg`, with all the resources needed to run Terraform and create all the organization projects.
   * This step must be executed by an user with admin privileges in the organization, because it needs to create IAMs that are able to create projects and associate the billing account to them.
1. `rake apply_infra`
   * This will create all the projects in the organization. Each project is defined by the content of a directory in `common/live/(stg|prd)/infra`

WARNING: The command `rake destroy_infra` of the GCP part of this project can disable the DNS API driving to an issue where Terraform is unable to refresh the state at the next executions. Avoid the use of `rake destroy_infra`, and only remove the most expensive resources using `rake destroy`. A Jira ticket has been created to fix this behavior: https://issues.gpii.net/browse/GPII-3332

## Testing the gpii-infra common

The only way that we have to test this code is using another dedicated GCP organization dedicated. The environment variables needed to do so are hardcoded in the `live/stg/Rakefile` in order to avoid possible overwriting of the production resources.

The code used by the `live/stg` environment is the same as used in `live/prd` but all the changes will be preformed in the testing organization.

Once the testing organization has all the resources (DNS zones and projects), it is possible to spin up the clusters defined in the `gcp` part of the repository. To do so some environment variables must be set first.

i.e to spin up the a dev cluster:

From the root of the repository:
```
 export ORGANIZATION_ID=327626828918
 export TF_VAR_organization_name=gpii2test
 export TF_VAR_organization_domain=test.gpii.net
 export USER=doe
 cd gcp/live/dev
 rake
 # (wait until all the resources are created)
 curl -k https://preferences.doe.dev.gcp.test.gpii.net/preferences/carla
 rake destroy
```

## Adding a dev project

The projects are defined in the directory tree `common/live/stg/infra/`. To add a new user make a copy of the user `john`, edit the file john/terraform.tfvars and change the `project_*` variables. Example:

```
cd common/live/stg/infra/
cp -r john $USER
#(edit $USER/terraform.tfvars)
  project_name = "dev-$USER"
  project_owner = "user:$USER@RtF"
#(save)
cd common/live/stg/
rake apply_infra
```

Once the `rake apply_infra` command has finished the resources for the new user must be created. Go to the `gcp` part of the repository and spin up the environment. Remember to use the same string for the USER environment variable.

## Shutting down a project

The deletion of a project is not implemented to be performed automatically yet. First be sure that all the resources of such project are deleted. You can use the `rake destroy` command of the `gcp` part to deleted most of them (or at least the most expensive ones). After that, the command `rake destroy_infra` will destroy most of the resources left. But since the `rake destroy_infra` doesn't finish fine, some resources could be left in GCP, so they need to be deleted manually.

## Removing a dev project

To remove a dev environment entirely (e.g. due to offboarding a developer):

1. Delete the Project (IAM & Admin `->` Settings `->` Shut Down).
1. Delete Project's associated DNS zone (Network services `->` Cloud DNS `->` `dev-gcp-gpii-net` `->` Select zone `->` Delete zone).
   * Alternately, `cd common/live/prd && rake destroy_module"[infra/dev/offboarded-developer] RAKE_REALLY_RUN_IN_PRD=true RAKE_REALLY_DESTROY_IN_PRD=true" -- it will delete some things but will not finish successfully.
1. Delete the developer's entry in `common/live/prd/infra/dev/offboarded-developer`.

## Importing existing resources

In the case that we need to import existing resources to the TF state file, we need to perform the following steps:

1. Get in to the Docker container and project path.
   ```
   cd common/live/prd
   rake sh
   cd /project/live/prd/infra/$PROJECT/zone
   # or
   cd /project/live/prd/infra/dev/$USER
   ```
1. Execute a `terragrunt plan`
1. You will see which resources are going to be created. If any of those already exists they need to be imported:

   ```
   # Project
   terragrunt import google_project.project gpii-gcp-dev-$USER
   # API Services
   terragrunt import google_project_services.project gpii-gcp-dev-$USER
   # Storage Buckets
   terragrunt import google_storage_bucket.project-tfstate gpii-gcp-dev-$USER-tfstate
   # Service Accounts
   terragrunt import google_service_account.project projects/gpii-gcp-dev-$USER/serviceAccounts/projectowner@gpii-gcp-dev-$USER.iam.gserviceaccount.com
   ```

In the case of the DNS-root, the resources are spread AWS and Google DNS:

1. Get in to the Docker container and project path.
   ```
   cd common/live/prd
   rake sh
   cd /project/live/prd/infra/dns-root
   ```
1. Execute a `terragrunt plan`
1. You will see which resources are going to be created. If any of those already exists they need to be imported:

   ```
   # DNS zones
   terragrunt import module.gcp_zone_in_aws.aws_route53_record.main_ns  Z26C1YEN96KOGI_gcp.gpii.net_NS
   terragrunt import module.gcp_zone_in_aws.aws_route53_zone.main Z29SXC5CAHOH1D
   ```

NOTE: the above sample lines have been used in our last import. Perhaps other resources need to be imported, following the same patterns. It was not possible to cover all the resources as they were not created at that time.
