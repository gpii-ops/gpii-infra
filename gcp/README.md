# gpii-infra GCP

This directory manages GPII infrastructure in [Google Cloud Project (GCP)](https://cloud.google.com/). It is organized as an [exekube](https://github.com/exekube/exekube) project and is very loosely based on the [exekube demo-apps-project](https://github.com/exekube/demo-apps-project)

Initial instructions based on [exekube's Getting Started](https://exekube.github.io/exekube/in-practice/getting-started/) (version 0.3.0).

## Setup

1. Clone this repo.
1. Clone [exekube](https://github.com/exekube/exekube).
   * The `gpii-infra` clone and the `exekube` clone must be siblings in the same directory (there are some references to `../exekube`).
1. `cd exekube && docker-compose build google`
1. `cd ../gpii-infra/gcp`
1. `alias xk='docker-compose run --rm --service-ports xk'`
1. `export ENV=dev`
1. `export ORGANIZATION_ID=<YOUR-ORGANIZATION-ID>`
   * Create a GCP Free Trial account. Get the Organization ID from there.
1. `export BILLING_ID=<YOUR-BILLING-ID>`
   * Create a GCP Free Trial account. Get the Billing ID from there.
1. `export TF_VAR_project_id=xk-mrtyler`
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
