# gpii-infra GCP

This directory manages GPII infrastructure in [Google Cloud Project (GCP)](https://cloud.google.com/). It is organized as an [exekube](https://github.com/exekube/exekube) project and is very loosely based on the [exekube demo-apps-project](https://github.com/exekube/demo-apps-project)

## Getting started

Start here if you are a GPII developer who wants to create a personal GPII Cloud for development or testing.

### Install packages

1. Install Ruby **==2.4.3**.
   * There's nothing particularly special about this version. We could relax the constraint in Gemfile, but a single version for everyone is fine for now.
   * I like [rvm](https://rvm.io/) for managing and versioning Ruby environments.
   * If you're using a package manager, you may need to install "ruby-devel" as well.
1. Install [rake](https://github.com/ruby/rake) **==12.3.0**, probably via `gem install rake -v 12.3.0`.
1. Install [Docker](https://www.docker.com/get-started), and be sure that the **docker-compose** application is available from the command line.

### Get an account

Ask the Ops team to set up an account and train you. (The training doc is [here](../USER-TRAINING.md) if you're curious.)

### Configure browser to use RtF user

Users who already had an RtF email address/Google account usually have performed these steps already.

* [Sign in to your RtF Google Account](https://myaccount.google.com) using your preferred browser.
   * If you already have another Google Account configured in your preferred browser (e.g. a personal Gmail account), go to the User dropdown on the top-right `->` Add account
* Ops will provide the email address and password.
* Google may prompt you for a code from an MFA token.
   * I think this might happen if an admin creates your account, logs into it to test something, and the account's MFA "grace period" expires.
   * If this happens, ask an Ops team member to generate Backup Codes for your account and give them to you. You will need these to log in, and to configure MFA (see below).
* Google will prompt you for a phone number to verify your account. You must pass this step before you can set up MFA.
   * If you cannot (or do not wish to) provide Google a phone number, an Ops team member can use their own phone number to verify the account. After MFA is configured (see below), the Ops team member can remove their phone number from the user's account.

### Enable Multi-Factor Authentication (MFA) on your account

* From [Google 2-Step Verification](https://www.google.com/landing/2step/), click Get Started and follow the prompts.
   * I like [Duo](https://duo.com/product/trusted-users/two-factor-authentication/duo-mobile), but any tool from [Amazon's list](https://aws.amazon.com/iam/details/mfa/) should be fine. See also [Google's documentation](https://www.google.com/landing/2step/).
   * If you don't have access to a separate device for MFA (e.g. a smartphone, tablet, or hardware device such as a Yubikey), it is acceptable (though not recommended -- especially for administrators) to run an MFA tool on your development machine. A few of us use [Authy](https://authy.com/download/) for this.

### One-time Stackdriver Workspace setup

1. Go to [Stackdriver Monitoring Overview](https://app.google.stackdriver.com), you will be redirected to Project Setup page if needed.
1. Select "Create a new Workspace". Click "Continue".
1. Make sure that you see your project id under "Google Cloud Platform project". Click "Create workspace".
1. Make sure that only your project is selected under "Add Google Cloud Platform projects to monitor". Click "Continue".
1. Click "Skip AWS Setup".
1. Click "Continue".
1. Select desired reports frequency under "Get Reports by Email". Click "Continue".
1. Finished initial collection! Click "Launch Monitoring".

### Creating an environment

1. Clone this repo (or update to the tip of gpii-ops/master).
1. `cd gpii-infra/gcp/live/dev`
1. `rake update_exekube`
1. `rake`
   * The first time you deploy a GPII Cloud (or after you run `rake clobber`), you will be prompted to authenticate **twice**. Follow the instructions in the prompts.
   * If your browser is configured with multiple Google accounts (e.g. a personal Gmail account as well as an RtF Gmail account), make sure to choose the right one when authenticating.
1. Once `rake` finishes, GPII Cloud endpoints should be available at `https://<service>.<your cluster name>.dev.gcp.gpii.net/`
   * e.g. https://preferences.alfredo.dev.gcp.gpii.net/preferences/carla
   * e.g. https://flowmanager.alfredo.dev.gcp.gpii.net
1. Lots of information about your GPII Cloud is available through the [Google Cloud Console](https://console.cloud.google.com). Some common links:
   * [Kubernetes clusters](https://console.cloud.google.com/kubernetes/list)
   * [Logs](https://console.cloud.google.com/logs/viewer?&advancedFilter=search%20text)
      * I find the "Advanced filter" (drop down at far right of filter box `->` Convert to advanced filter)  less confusing that "Basic mode"
   * [Monitoring, metrics, and alerts](https://app.google.stackdriver.com/)
   * [Storage](https://console.cloud.google.com/storage/browser)
1. To see a list of other commands you can try: `rake -T`
1. If something didn't work, see [Troubleshooting / FAQ](#troubleshooting--faq).

### Interacting with an environment

1. `rake display_cluster_info` shows some helpful links.
1. `rake display_cluster_state` shows debugging info about the current state of the cluster. This output can be helpful when asking for help.
1. `rake display_universal_image_info` shows currently deployed [gpii/universal](https://github.com/GPII/universal) image SHA and link to GitHub commit that triggered the build.
1. `rake sh` opens an interactive shell inside a container on the local host that is configured to communicate with your cluster (e.g. via `kubectl` commands).
   * `rake sh` has some issues with interactive commands (e.g. `less` and `vi`) -- see https://issues.gpii.net/browse/GPII-3407.
1. `rake plain_sh` is like `rake sh`, but not all configuration is performed. This can be helpful for debugging (e.g. when `rake sh` does not work) and with interactive commands.
1. To `curl` a single couchdb instance: `kubectl exec --namespace gpii couchdb-couchdb-0 -c couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/`

### Tearing down an environment

1. `cd gpii-infra/gcp/live/dev`
1. `rake destroy`
   * This is the important one since it shuts down the expensive bits (VMs in the Kubernetes cluster, mostly)
1. (Optional) `rake clean`
   * This command is optional, but is recommended after `rake destroy`. It removes temporary and cache files that can cause trouble after an unfinished deployment.
1. (Optional) `rake clobber`
   * This command is also optional, but cleans up more files than `rake clean`. It will leave the local command-line environment without generated data, including authentication (so you will need to authenticate again after running `rake clobber`).

### Less common options when creating an environment
1. **dev** environments use the environment variable `$USER`. `$USER` in your command-line environment must match your RtF account. If you have any doubts, ask the ops team.
1. Infrastructure developers may wish to clone [the gpii-ops fork of exekube](https://github.com/gpii-ops/exekube).
   * The `gpii-infra` clone and the `exekube` clone should be siblings in the same directory (there are some references to `../exekube`). This is useful for testing the Terraform modules allocated in the exekube's project. If you want to have those modules in your exekube container uncomment the proper line in the docker-compose.yml file before running any command.
1. By default you'll use the RtF Organization and Billing Account.
   * You can use a different Organization or Billing Account, e.g. from a GCP Free Trial Account, with `export ORGANIZATION_ID=111111111111` and/or `export BILLING_ID=222222-222222-222222`.
1. By default your K8s cluster and related resources will be deployed into `us-central1`.
   * You can use a different GCP region -- see [I want to spin up my dev environment in a different region](README.md#i-want-to-spin-up-my-dev-environment-in-a-different-region).
1. The [Google Cloud Console](https://console.cloud.google.com) includes [Google Cloud Shell](https://cloud.google.com/shell/docs/) which is an interactive terminal embedded in the GCP dashboard. To use it, click on the icon at the top right of the Console, next to the magnifier icon.
   * Once the shell opens in your browser, execute the following to manage the Kubernetes cluster using the embedded `kubectl` command:
   1. `gcloud container clusters get-credentials k8s-cluster --zone YOUR_INFRA_REGION`
   1. `kubectl -n gpii get pods`

   It's a Debian GNU/Linux so all the `apt` commands are also available.

   You can also upload/download files using such functionality that you will find in the top right menu of the interactive shell.

### Less common options when tearing down an environment
1. `rake destroy_infra`
   * This command works only partially; see [GPII-3332](https://issues.gpii.net/browse/GPII-3332).
   * Exekube recommends leaving these resources up since they are cheap
1. There's no automation for destroying the Project and starting over. I usually use the GCP Dashboard.
   * Note that "deleting" a Project really marks it for deletion in 30 days. You can't create a new Project with the same name until the old one is culled.
   * See also [Shutting down a project](https://github.com/gpii-ops/gpii-infra/tree/master/common#shutting-down-a-project) and [Removing a dev project](https://github.com/gpii-ops/gpii-infra/tree/master/common#removing-a-dev-project).

## Contacting the Ops team

Want help with your cluster? Is production down, or is there some other kind of operational emergency? See [CONTACTING-OPS.md](../CONTACTING-OPS.md).

## What are all these environments?

An "environment" describes a (more-or-less) self-contained cluster of machines running the GPII and its supporting infrastructure (e.g. monitoring, alerting, backups, etc.). There are a few types of environments, each with different purposes.

### dev-$USER

These are ephemeral environments, generally used by developers working on the `gpii-infra` codebase or on cloud-based GPII components. CI creates some ephemeral environments (`dev-gitlab-runner`, `dev-doe`) for integration testing.

#### Service Level Objective

* No guarantee of service for development environments.
* Ops team does not receive alerts about problems.
* Ops team assists developers with operation and debugging when convenient for the team (i.e. do not use emergency or out-of-hours contact methods unless there are extraordinary circumstances).

### stg

This is a shared, long-lived environment for staging / pre-production. It aims to emulate `prd`, the production environment, as closely as possible.

Deploying to `stg` verifies that the gpii-infra code that worked to create a `dev-$USER` environment from scratch also works to update a pre-existing environment. This is important since we generally don't want to destroy and re-create the production environment from scratch.

Because `stg` emulates production, it will (in the future) allow us to run realistic end-to-end tests before deploying to `prd`.

#### Service Level Objective

* No guarantee of service for development environments (stg is a development environment).
* Ops team receives alerts about problems, and addresses them when convenient for the team (i.e. we won't wake up an on-call engineer, but we will investigate during business hours)
* Ops team makes an effort to keep stg stable and available for ad-hoc testing, but may disrupt the environment at any time for our own testing.

### prd

This is the production environment which supports actual users of the GPII.

Deploying to `prd` requires a [manual action](https://docs.gitlab.com/ce/ci/yaml/#manual-actions). This enables automated testing (CI) and a consistent deployment process (CD) while providing finer control over when changes are made to production (e.g. on a holiday weekend when no engineers are around).

#### Service Level Objective

* Ops team treats availability of production as highest priority.
* Ops team receives alerts about problems, and addresses them as soon as possible.
   * Today we do not have automated 24x7 on-call support. However, a human observing a serious, customer-affecting problem in prd should [contact someone on the Ops team](../CONTACTING-OPS.md), no matter the time or day.
* Ops team communicates both planned and unplanned downtime to stakeholders via the `outage@RtF` mailing list (see [Downtime procedures](#downtime-procedures).

## Troubleshooting / FAQ

### Running manually in non-dev environments (stg, prd)

See [CI-CD.md#running-in-non-dev-environments](../CI-CD.md#running-manually-in-non-dev-environments-stg-prd)

### I want to test my local changes to GPII components in my cluster

1. Build a local Docker image containing your changes.
1. Push your image to Docker Hub under your user account (e.g. `docker build -t mrtyler/universal . && docker push mrtyler/universal`).
1. Edit `gpii-infra/shared/versions.yml`. Find your component and edit the `upstream.repository` field to point to your Docker Hub user account.
   * E.g., `gpii/universal -> mrtyler/universal`
1. Clone https://github.com/gpii-ops/gpii-version-updater/ in the same directory as your gpii-infra clone.
   * The `gpii-version-updater` clone and the `gpii-infra` clone should be siblings in the same directory (there are some references to `../gpii-infra`).
1. `cd gpii-version-updater`
1. Follow the steps at [gpii-version-updater: Installing on host](https://github.com/gpii-ops/gpii-version-updater/#installing-on-host) (or [gpii-version-updater: Running in a container](https://github.com/gpii-ops/gpii-version-updater/#running-in-a-container).
1. `rake sync`
1. `cd ../gpii-infra/gcp/live/dev && rake`

### I need to interact with Helm directly, e.g. because a Helm deployment was orphaned due to an error while running `rake`

1. `cd gcp/live/dev` (or another environment)
1. `rake sh`
1. `helm --tiller-namespace kube-system list --tls --tls-verify --tls-ca-cert /project/live/dev/secrets/kube-system/helm-tls/ca.cert.pem --tls-cert /project/live/dev/secrets/kube-system/helm-tls/helm.cert.pem  --tls-key /project/live/dev/secrets/kube-system/helm-tls/helm.key.pem`
   * Adjust paths for the environment you're using.

### I want to spin up my dev environment in a different region

1. `cd gpii-infra/gcp/live/dev`
1. Check for an existing Keyring in the new region:
   * `rake sh"[gcloud kms keyrings list --location mars-north1]"`
1. If this is your first time spinning up a dev environment in a new region, or if you're sure you've never created a dev environment in the specified region, proceed to [Using a region for the first time](README.md#using-a-region-for-the-first-time) and skip the Destroy step.
1. If you see `Listed 0 items`, proceed to [Using a region for the first time](README.md#using-a-region-for-the-first-time).
1. If you see something like `projects/gpii-gcp-dev-mrtyler/locations/mars-north1/keyRings/keyring`, proceed to [Using a region where you previously had a dev environment](README.md#using-a-region-where-you-previously-had-a-dev-environment).

#### Using a region for the first time
1. Destroy all deployed resources, Terraform state, and secrets in the old region:
   * `rake destroy_hard`
1. `export TF_VAR_infra_region=mars-north1`
1. Your environment is ready to re-deploy with `rake`
1. If you encounter an error like one of the following, proceed to [Using a region where you previously had a dev environment](README.md#using-a-region-where-you-previously-had-a-dev-environment).
   * `google_kms_key_ring.key_ring: the plan would destroy this resource, but it currently has lifecycle.prevent_destroy set to true.`
   * `google_kms_key_ring.key_ring: Error creating KeyRing: googleapi: Error 409: KeyRing projects/gpii-gcp-dev-tyler/locations/us-east4/keyRings/keyring already exists., alreadyExists`

#### Using a region where you previously had a dev environment
1. Destroy all deployed resources, Terraform state, and secrets in the old region:
   * `rake destroy_hard`
   * If you have run other rake commands since `destroy_hard`, e.g. because you tried the "Using a region for the first time" workflow and encountered an error, run `destroy_hard` again here.
1. `export TF_VAR_infra_region=mars-north1`
1. `rake import_keyring`
   * This command is experimental and doesn't do a lot of error checking. If this step fails, try running its constituent commands one-by-one.
1. `rake rotate_secrets_key`
   * These `rotate_` steps are not needed if all the Keys have an enabled primary version. However, rotating is safe either way and prevents some problems so it is the recommended workflow.
1. `rake rotate_secrets_key"[gcp-stackdriver-export]"`
1. Your environment is ready to re-deploy with `rake`

### My environment is messed up and I want to get rid of it so I can start over

These steps are ordered roughly by difficulty and disruptiveness.

#### Easy, ordinary steps

1. `rake unlock` - if you orphaned a Terraform lock file, e.g. by Ctrl-C during a Terraform run
1. `rake destroy` - the cleanest way to terminate a cluster. However, it may fail in certain circumstances.
1. `rake clobber` - cleans up generated files. You will have to authenticate again after clobbering

#### More difficult, disruptive steps

If you're at these steps, you probably want to [ask #ops for help](../CONTACTING-OPS.md).

1. `rake destroy_hard` - cleans up terraform state files and secrets in Google Storage
   * **NOTE:** This will "orphan" any resources Terraform created for you previously and will be difficult to recover from
1. Manually delete "ordinary" resources using the GCP Dashboard: Kubernetes Cluster, Disks, Snapshots, Logging Export rules, Logging Exclusion rules
1. Manually delete "infra" resources using the GCP Dashboard: Network stuff, Network services `->` Cloud DNS, Google Storage buckets.
   * NOTE: If you delete the `-tfstate` bucket, you will need to ask Ops (or CI) to re-deploy `common-prd`. Unless things are really messed up, you may prefer to leave the bucket itself alone and delete all its contents.

### I want to work on a different dev cluster

**Note: this is an advanced / non-standard workflow.** There aren't a lot of guard rails to prevent you from making a mistake. User discretion is advised.

Examples of when you might want to do this:
* (Most common) Cleaning up when CI ends up with a broken `dev-gitlab-runner` cluster, e.g. the CI server reboots and orphans a Terraform lock.
* Collaborating with another developer in their dev cluster.
* Running multiple personal dev environments (e.g. `dev-mrtyler-experiment1`).
   * Note that this additional dev environment will require configuration in [common/](../common).

1. Prepend `USER=gitlab-runner` to all `rake` commands.
   * Or, to add an additional dev cluster: `USER=mrtyler-experiment1`

### I need to work with my tfstate bucket directly

For example: a developer deleted their tfstate bucket in GCS and re-created it with the wrong permissions. You need to back up the contents of the bucket so Terraform can destroy it and re-create it with the correct permissions.

1. Entities in the tfstate bucket may use one of two encryption types:
   * Google-managed - for initial bootstrapping, storage of tfstate for the secrets themselves
   * Customer-supplied - managed with our [secrets code](https://github.com/gpii-ops/gpii-infra/blob/master/shared/rakefiles/secrets.rb)
2. For entities encrypted with a Google-managed key (`infra/`, `secret-mgmt/`):
   * `rake sh
   * `gsutil ...`
3. For entities encrypted with a customer-supplied key (`k8s/`, `locust/`):
   * `rake sh`
   * `echo -e "[GSUtil]\nencryption_key = $TF_VAR_key_tfstate_encryption_key" > ~/.boto`
   * `gustil ...`
4. The tfstate bucket contains entities with *both kinds* of encryption. When reconstructing the bucket, you must use (or not use, i.e. move out of the way) the custom `.boto` file described above.
5. Some Google documentation for context, [Using Encryption Keys](https://cloud.google.com/storage/docs/gsutil/addlhelp/UsingEncryptionKeys).

### My deploy is stuck on `Waiting for all CouchDB pods to join the cluster... 1 of 2 pods have joined the cluster`

1. Unfortunately, this is a [known issue](https://issues.gpii.net/browse/GPII-3624) that happens periodically. It is a result of "split brain" -- both couchdb instances think they are the leader of their own cluster.
   * To find out if you're suffering from this problem:
      * `rake display_cluster_state`
      * Look for the `_membership` output
      * If `couchdb-couchdb-0` only knows about `couchdb-couchdb-0` and `couchdb-couchdb-1` only knows about `couchdb-couchdb-1`, you have split brain
1. The easiest workaround is to destroy couchdb, then re-run the deployment:
   * `rake destroy_module"[k8s/gpii/couchdb]" && rake`
1. If you need to, you may be able to repair the split brain manually using [CouchDB Cluster Management commands](https://docs.couchdb.org/en/stable/cluster/nodes.html).

### Errors trying to enable/disable Google Cloud APIs

When destroying an environment completely (`rake destroy`), or creating an environment for the first time or after complete destruction (`rake deploy`), we disable/enable some Google Cloud APIs. This action is asynchronous and can take a few minutes to propagate.

1. If you encounter an error like this during a `rake` run:

```
* google_project_service.services.1:
Error enabling service:
Error enabling service ["container.googleapis.com"]
for project "gpii-dev-mrtyler": googleapi:
Error 400: Precondition check failed., failedPrecondition
```

then try again.

See https://github.com/exekube/exekube/pull/91 for further discussion.

2. There is a slightly different error related to enabling/disabling GCP APIs:

```
Error 403: The caller does not have permission, forbidden
```

This happens when trying to enable an API that is already enabled. This shouldn't happen in normal operation, but a quick fix is to run something like this for each affected API:

```
rake sh["gcloud services disable container.googleapis.com"]
```

### Error (gcloud.iam.service-accounts.keys.create) RESOURCE_EXHAUSTED: Maximum number of keys on account reached

This happens due to limitation of maximum 10 keys per ServiceAccount.
If you see this error during any `rake` execution, run `rake destroy_sa_keys` and then try again.

### oauth2: cannot fetch token: 400 Bad Request

This happens when you run some commands in an environment (usually `stg` or `prd`) before, did not run `rake clobber`, CI run after that and destroyed your SA key. Error is basically saying that locally stored SA key is invalid and needs to re-issued.
Solution is to `rake clobber` and re-authenticate. This will not affect your running cluster, only local state.

### helm_release.release: rpc error: code = Unavailable desc = transport is closing

This caused by locally missing helm certificates (similarly to previous error, it usually happens when working to `stg` or `prd` environment, after `rake clobber`) and can be fixed by running `rake fetch_helm_certs`.

### helm_release.release: error creating tunnel: "could not find tiller"

This some times happens during forceful cluster re-creation (for example when updating oauth scopes), and caused by Terraform failing to trigger `helm-initializer` module deployment.
Solution is to run `rake deploy_module['k8s/kube-system/helm-initializer']`.

### The metric referenced by the provided filter is unknown. Check the metric name and labels. (Google::Gax::RetryError)

This some times happens, when Stackdriver Ruby client is trying to apply alerting policy on newly created log-based metric. Solution is to wait 5-10 minutes and try again.

### [ERROR]: Deadline exceeded while destroying resources!

The most common solution for this is to [create your Stackdriver Workspace](README.md#one-time-stackdriver-workspace-setup).

## Common plumbing

The environments that run in GCP need some initial resources that must be created by an administrator first. The [common part of this repository](../common) has the code and the instructions to do so.

## Continuous Integration / Continuous Delivery

See [CI-CD.md](../CI-CD.md).

## Authentication workflow

There are number of infrastructure components that require access tokens to interact with various GCP services.

* For developers we use [application-default credentials](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/). This approach allows us to trace every action performed by individual users back to their G Suite accounts.
   * After initial interactive login using your G Suite account you will be asked to login one more time to retrieve application-default credentials.
   * Locally stored credentials can be destroyed with `rake clobber`.
* For CI we use `projectowner` service account, so all CI actions appear in audit logs under that SA.
   * SA credentials are being generated and stored locally during [CI setup](#one-time-ci-setup).
   * In case SA credentials are present locally, application-default credentials are ignored.

## Permissions

The permissions in this project are set in three different levels: at organization level, at project level and at resource level.

At the organization level we have the group _cloud-admin@raisingthefloor.org_ which contains the list of users that will manage the projects of the organization and has the high level permissions to do so. Also we have a Service Account (SA) dedicated for the project creation and the billing association: _projectowner@gpii-common-prd.iam.gserviceaccount.com_. This SA only has the enough permissions to create projects, assciate them to the billing account and create the IAMs needed in such project to allow the owner to create the resources inside it. The SA _projectowner@gpii2test-common-stg.iam.gserviceaccount.com_ must also be in the organization level, as the billing account is associated to this organization and it is used to attach it to the testing organization _test1.gpii.net_.

Each project has a SA which performs almost all the actions over the resources of such project. This SA only has the permissions needed to deploy GPII cloud. This SA doesn't have permissions to make changes outside the project which owns it.

The permissions set at resource level are automaticallly set by Terraform in order to work properly among the rest of the components of the GPII cloud. i.e the storage bucket permissions for exported logs https://console.cloud.google.com/storage/browser/gpii-gcp-dev-alfredo-exported-logs?project=gpii-gcp-dev-alfredo

More details about which roles and permissions are set in the infrastructure can be found in the [PERMISSIONS.md](PERMISSIONS.md)

## Monitoring and alerting

We use [Stackdriver Beta Monitoring](https://cloud.google.com/monitoring/kubernetes-engine/) to collect various system metrics, navigate through them with [Kubernetes Dashboard](https://app.google.stackdriver.com/kubernetes), and send alerts when they violate thresholds that are being set by [Stackdriver Alerting Policies](https://app.google.stackdriver.com/policies).

Due to the lack of Terraform integration we use [Ruby client](https://github.com/gpii-ops/gpii-infra/blob/master/shared/rakefiles/stackdriver.rb) to apply / update / destroy Stackdriver's resource primitives from their [json configs](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/modules/gcp-stackdriver-monitoring/resources).

### One-time Stackdriver Workspace setup

See [Getting started: One-time Stackdriver Workspace setup](README.md#one-time-stackdriver-workspace-setup)

### To add new resource / debug existing resources:
1. Add new resource / modify existing resource using corresponding Stackdriver Dashboard. **Supported resources are:**
   * [Notification channels](https://app.google.stackdriver.com/settings/accounts/notifications/email) (only email notification channel type is currently supported, all notification channels are being applied to every alert policy).
   * [Uptime checks](https://app.google.stackdriver.com/uptime).
   * [Alert policies](https://app.google.stackdriver.com/policies).
1. Run `TF_VAR_stackdriver_debug=1 rake deploy_module['k8s/stackdriver/monitoring']`.
1. You will find json blobs for all supported Stackdriver resources in the output.
1. To add new resource config into `gcp-stackdriver-monitoring` module:
   * Copy json blob that you obtained on previous step into proper [resource directory](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/modules/gcp-stackdriver-monitoring/resources). Give a meaningful name to a new resource file. You can use `jq` to help with formatting.
   * Remove all `name`, `creation_record`, and `mutation_record` attributes.
   * Set `notification_channels` to `[]` (this value will be populated dynamically later).
   * Repeat from **step 2.** All newly configured resources will be synced with Stackriver.
1. In case you added new email notification channel, you may want to authorize new sender to post to [Alerts Group](https://groups.google.com/a/raisingthefloor.org/forum/#!pendingmsg/alerts). Follow the link, select new message and click "Post and always allow future messages from author(s)" button.

### To configure Dashboards for your project:
1. Go to [Metrics Explorer](https://app.google.stackdriver.com/metrics-explorer).
1. Select resource type, metric and configure other parameters for the chart that you want to add to your Dashboard.
1. Click "Save Chart". Select existing one or new Dashboard. Click "Save".
1. Your Stackdriver Dashboard should be now available in [Dashboard Manager](https://app.google.stackdriver.com/dashboards).

### To receive notifications in Slack:
1. Go to [Workspace Notification Settings - Slack](https://app.google.stackdriver.com/settings/accounts/notifications/slack/).
1. Click "Add Slack Channel".
1. Click "Authorize Stackdriver" – this will redirect to Slack's authentication page.
1. Click "Authorize".
1. Enter channel name including "#". Click "Test Connection" and then "Save".
1. Now you can use new notification channel in `gcp-stackdriver-monitoring` module. Here is example json: `{"type":"slack","labels":{"channel_name":"#alerts"},"user_labels":{},"enabled":{"value":true},"immutable":{"value":true}}`.

## Working with CouchDB data

You can run all `kubectl` commands mentioned below inside of an interactive shell started with `rake sh`.

### Data corruption on a single CouchDB replica

In this scenario we rely on CouchDB ability to recover from loss of one or more replicas (our current production CouchDB settings allow us to lose up to 2 random nodes and still keep data integrity). The best course of action as follows:

1. Make sure that you figured affected CouchDB pod properly
1. There is a PVC object, associated with affected CouchDB pod. Let's say affected pod is `couchdb-couchdb-1`, then corresponding PVC is `database-storage-couchdb-couchdb-1`, located in the same namespace.
1. Delete associated PVC and then affected pod. For our example case:
   * `kubectl --namespace gpii delete pvc database-storage-couchdb-couchdb-1`
   * `kubectl --namespace gpii delete pod couchdb-couchdb-1`
1. After target pod is terminated, Persistent Disk that was mounted into it thru corresponding PVC will be destroyed as well.
1. When new pod is created to replace deleted one, corresponding PVC will be created as well, and, thru it, new PV object for new GCE PD.
1. Run `rake deploy_module[couchdb]` to patch newly created PV with annotations for `k8s-snapshots`.
1. CouchDB cluster will replicate data to recreated node automatically.
1. Corrupted node is now recovered.
   * You can check DB status on recovered node with `kubectl exec --namespace gpii -it couchdb-couchdb-N -c couchdb -- curl -s http://$TF_VAR_couchdb_admin_username:$TF_VAR_couchdb_admin_password@127.0.0.1:5984/gpii/`, where N is node index.

### The CouchDB cluster won't converge because one of its disks is in the wrong zone

Consider this scenario:
* A Kubernetes cluster has 3 Nodes, one each in us-central1-a, us-central1-b, and us-central1-c.
* On this Kubernetes cluster runs a CouchDB cluster with 3 replicas, one on each Node (and thus one in each Zone).
* Each CouchDB replica is attached to a Persistent Volume, which is tied to a specific Zone.
* A change is deployed which requires the Kubernetes cluster to be destroyed and re-created. The new Kubernetes cluster has 3 Nodes, but now they are in us-central1-a, us-central1-b, and us-central1-f (i.e. no Nodes in us-central1-c).
* CouchDB is deployed. The replicas in us-central1-a and us-central1-b are scheduled so that they can re-attach to the Persistent Volumes containing their data.
* But the replica that wants to re-attach to the PV in us-central1-c cannot do so, because there is no Node in us-central1-c on which to run.
   * You'll know you're in this state if one CouchDB Pod can't start at all (`0/2 Pending`), and there are messages about `0/3 nodes are available: 3 node(s) had no available volume zone` in the output of `rake display_cluster_state`.

The workaround is to manually move the Persistent Disk that backs the Persistent Volume into a Zone where it can be attached by a CouchDB replica:
1. Find a destination Zone that has a Node with no CouchDB Pod running on it. Note this for later.
1. Find the un-attached Persistent Disk used by CouchDB.
   * Usually this will be the one with an empty "In use by" column in the GCP Dashboard.
1. Move the un-attached Disk to the destination Zone
   * `gcloud compute disks move gke-k8s-cluster-000000-pvc-11111111-2222-3333-4444-555555555555 --zone us-central1-AAA --destination-zone us-central1-ZZZ`
1. Edit the PVC associated with the un-attached Disk.
   * `kubectl -n gpii edit pv pvc-11111111-2222-3333-4444-555555555555`
   * Find all mentions of the old Zone and replace them with the destination Zone.
1. Kubernetes should run the CouchDB Pod in the correct Zone, and CouchDB should attach to the Persistent Disk. Verify this with e.g. `kubectl -n gpii get pods` or the GKE Dashboard.
   * You may need to deploy the couchdb module again (`rake deploy_module"[k8s/gpii/couchdb]"`), nudge the Pod (`kubectl -n gpii delete pod couchdb-couchdb-NNN`), or destroy and re-create the couchdb module (`rake redeploy_module"[k8s/gpii/couchdb]"`).
1. When you are sure the CouchDB cluster is healthy, delete any new Snapshots you created (k8s-snapshots manages its own Snapshots).

An alternative workaround is to do a snapshot-restore cycle to move the Persistent Disk to a better Zone:
1. Find a Zone that has a Node with no CouchDB Pod running on it. Note this for later.
1. Open Google Cloud console, go to "Compute Engine" -> "Disks".
1. Find the un-attached Persistent Disk used by CouchDB.
   * Usually this will be the one with an empty "In use by" column.
   * Save the Disk's name, type, size, zone and description.
1. Select this Disk, then "Create Snapshot". Give the Snapshot a meaningful name.
   * If you are certain the latest Snapshot created by k8s-snapshots is up-to-date (e.g. because you shut down all services that talk to CouchDB before the latest Snapshot was created), you may skip this step and use that Snapshot instead.
1. `rake destroy_module"[k8s/gpii/couchdb]"`
   * This is a disruptive action! But if you're in this situation, the environment was probably down anyway. :)
   * You may need to manually delete the CouchDB StatefulSet, due to the Helm deployment failing and the StatefulSet becoming orphaned: `kubectl -n gpii delete statefulset couchdb-couchdb`
1. Manually remove the PVC associated with the Disk you noted earlier, e.g.: `kubectl -n gpii delete pvc pvc-11111111-2222-3333-4444-555555555555`
   * Kubernetes will reap the PV eventually.
   * Wait until both the PV and PVC are gone: `kubectl -n gpii get pv ; kubectl -n gpii get pvc`
1. Using the CouchDB disk you identified above:
   * Make sure you saved the disk name, type, size, zone and description.
   * Delete the PD in the old (wrong) zone, if it hasn't already been reaped.
   * Create a new PD from the Snapshot you identified earlier.
      * Use the same name, type, size, and description, but the new (correct) Zone you noted earlier.
1. `rake deploy_module"[k8s/gpii/couchdb]"`
1. Kubernetes should run the CouchDB Pod in the correct Zone, and CouchDB should attach to the Persistent Disk. Verify this with e.g. `kubectl -n gpii get pods` or the GKE Dashboard.
1. When you are sure the CouchDB cluster is healthy, delete any new Snapshots you created (k8s-snapshots manages its own Snapshots).

### Data corruption on all replicas of CouchDB cluster

There may be a situation, when we want to roll back entire DB data set to another point in the past. Current solution is disruptive, requires bringing entire CouchDB cluster down and some manual actions (we'll most likely automate this in future):

1. Choose a snapshot set that you want to restore, make sure that snapshots are present for all disks that are currently in use by CouchDB cluster.
1. Collect CouchDB disk names from PVCs with `kubectl --namespace gpii get pvc -l app=couchdb -o json | jq -r .items[].spec.volumeName`.
1. Get current number of CouchDB stateful set replicas with `kubectl --namespace gpii get statefulset couchdb-couchdb -o jsonpath="{.status.replicas}"`.
1. Scale CouchDB stateful set to 0 replicas with `kubectl --namespace gpii scale statefulset couchdb-couchdb --replicas=0`. This will cause K8s to terminate all CouchDB pods, all PDs that were mounted into them will be released. **This will prevent flowmanager and preferences services from processing customer requests!**
   * You may also want to scale `flowmanager` and `preferences` deployments to 0 replicas as well with `kubectl --namespace gpii scale deployment preferences --replicas=0` and `kubectl --namespace gpii scale deployment flowmanager --replicas=0`. This will give you time to verify that DB restoration is successful before allowing the DB to receive traffic again.
1. Destroy `k8s-snapshots` module with `rake destroy_module["k8s/kube-system/k8s-snapshots"]` to prevent new snapshots from being created while you working with disks.
1. Open Google Cloud console, go to "Compute Engine" -> "Disks".
1. Now, repeat for every CouchDB disk name you collected:
   * Save disk name, type, size, zone and description.
   * Pick proper snapshot.
   * Delete PD.
   * Create new PD from snapshot with the same name, type, size, zone and description.
1. Scale CouchDB stateful set back to number of replicas it used to have before with `kubectl --namespace gpii scale statefulset couchdb-couchdb --replicas=N`
1. Database is now restored to the state at the time of target snapshot.
   * You can check the status of all nodes with `for i in {0..N}; do kubectl exec --namespace gpii -it couchdb-couchdb-$i -c couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/_up; done`, where N is a number of CouchDB replicas.
1. Once DB state is verified and you sure that everything went as desired, you can scale `preferences` and `flowmanager` deployments back as well. From this point system functionality for the customer is fully restored.
1. Deploy `k8s-snapshots` module to resume regular snapshot process with `rake deploy_module["k8s/kube-system/k8s-snapshots"]`.

### Hack: Adding data to CouchDB

This is what I used to create a fake preference while verifying that volumes are restored correctly.

1. Run a container inside the cluster: `cd aws/dev && rake run_interactive`
1. From inside the container, install some tools: `apk update && apk add curl`
1. Define a record:
```
# Copied and modified from vicky.json.
data='
{
  "_id": "mrtyler",
  "type": "prefsSafe",
  "schemaVersion": "0.1",
  "prefsSafeType": "user",
  "name": "mrtyler",
  "password": null,
  "email": null,
  "preferences": {
    "flat": {
      "contexts": {
        "gpii-default": {
          "name": "HI EVERYBODY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
          "preferences": {
            "http://registry.gpii.net/common/stickyKeys": true
          }
        }
      }
    }
  },
  "timestampCreated": "2018-04-27T20:41:01.850Z",
  "timestampUpdated": null
}
'
```
1. Add the record: `curl -f -H 'Content-Type: application/json' -X POST http://couchdb.default.svc.cluster.local:5984/gpii -d "$data"`
1. Before the restore: verify that the new record is present.
1. After the restore: verify that the new record is no longer present.

### Manual process: Generating db data of user preferences and load it into a cluster's preferences server

#### Generate the data

1. `git clone git://github.com/gpii/universal.git && cd universal && npm install`
1. Put the preferences set you want to load into a folder, i.e.: _testData/myPrefsSets_.
1. Create a folder to store the db data, i.e.: _testData/myDbData_.
1. `node ./scripts/convertPrefs.js testData/myPrefsSets testData/myDbData`

Now there are two new files inside _testData/myDbData_, _gpiiKeys.json_ and _prefsSafes.json_.
Both files contain an array of JSON objects, i.e.:

```
[
    {
        "_id": "GPII-270-rbmm-demo",
        "type": "gpiiKey",
        "schemaVersion": "0.1",
        "prefsSafeId": "prefsSafe-GPII-270-rbmm-demo",
        "prefsSetId": "gpii-default",
        "revoked": false,
        "revokedReason": null,
        "timestampCreated": "2018-08-12T16:34:04.656Z",
        "timestampUpdated": null
    },
    {
        "_id": "MikelVargas",
        "type": "gpiiKey",
        "schemaVersion": "0.1",
        "prefsSafeId": "prefsSafe-MikelVargas",
        "prefsSetId": "gpii-default",
        "revoked": false,
        "revokedReason": null,
        "timestampCreated": "2018-08-12T16:34:04.661Z",
        "timestampUpdated": null
    }
]
```

And we want to edit these files to look like the following:

```
{ "docs":
    [
        {
            "_id": "GPII-270-rbmm-demo",
            "type": "gpiiKey",
            "schemaVersion": "0.1",
            "prefsSafeId": "prefsSafe-GPII-270-rbmm-demo",
            "prefsSetId": "gpii-default",
            "revoked": false,
            "revokedReason": null,
            "timestampCreated": "2018-08-12T16:34:04.656Z",
            "timestampUpdated": null
        },
        {
            "_id": "MikelVargas",
            "type": "gpiiKey",
            "schemaVersion": "0.1",
            "prefsSafeId": "prefsSafe-MikelVargas",
            "prefsSetId": "gpii-default",
            "revoked": false,
            "revokedReason": null,
            "timestampCreated": "2018-08-12T16:34:04.661Z",
            "timestampUpdated": null
        }
    ]
}

```

For the lazy:
* `cd testData/myDbData`
* `sed -i '1i { "docs": ' prefsSafes.json gpiiKeys.json`
* `sed -i '$ a }' prefsSafes.json gpiiKeys.json`

Congratulations, half of the work is done, now on to the load step.

#### Load the data into a cluster

Requirements:
* You are either an Op or you have been trained by one of them in using gpii-infra.
* Your computer is already set up to work with gpii-infra.
* And the most important thing, you know what you are doing. If not, ask the Ops team ;)

Note that we assume that you are going to perform these steps into an already up & running cluster. Also, remember that you always need to test the changes in your "dev" cluster first. In case that everything worked in your "dev" cluster, then proceed with "stg". If everything worked in "stg" too, then, proceed with "prd". In order for you to understand the differences beetween the different environments, check [this section](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/README.md#what-are-all-these-environments) from our documentation.

The process:

1. Go into the corresponding folder with the cluster name where you want to perform the process, "stg", "prd" or "dev". In this case We are going to perform the process in "dev": `cd gpii-infra/gcp/live/dev`.
1. Set up the env you are going to deal with: `rake sh`
__Note__ that if you are going to perform this in production (prd) you should do it from the _prd_ folder and remember to use the _RAKE_REALLY_RUN_IN_PRD=true_ variable when issuing the commands against the production cluster.
1. Open a port forwarding between the cluster's couchdb host:port and your local machine: `kubectl --namespace gpii port-forward couchdb-couchdb-0 5984 &`

Let's load the data, go back to the folder _testData/myDbData_ and run:
1. `curl -d @gpiiKeys.json -H "Content-type: application/json" -X POST http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@localhost:5984/gpii/_bulk_docs`

Unless you get errors, that's all. Now you can close the port forwarding as mentioned earlier.

### Downtime procedures

#### Before (planned) downtime

* Email `outage@` ahead of time explaining at a high level the what, when, and why of the planned downtime.
   * See below for a template.
   * The audience for `outage@` is all GPII Cloud stakeholders. Keep it brief and non-technical, and highlight any required actions.
* Consider manually disabling alerts related to your maintenance using the "Enabled" sliders on the [Stackdriver Alerting Policies dashboard](https://app.google.stackdriver.com/policies?project=gpii-gcp-prd).

#### During downtime

* Before performing manual or extraordinary actions, disable the CI/CD pipeline to prevent automated processes from interfering.
   * On the [Gitlab Project -> Settings -> General page](https://gitlab.com/gpii-ops/gpii-infra/edit), go to "Permissions" and disable "Pipelines".
      * This hides the CI/CD tab on the Project page. If you need to access that view (e.g. to view old pipeline logs), you can still navigate to it [directly](https://gitlab.com/gpii-ops/gpii-infra/pipelines). Note that running/retrying builds is disabled.

#### After downtime

* Create a record of any manual steps you perform, e.g. copy your terminal and paste it into a tracking ticket.
* If you manually disabled alerts previously, re-enable them.
* Email `outage@` that the downtime is ended.
   * See below for a template.
   * The audience for `outage@` is all GPII Cloud stakeholders. Keep it brief and non-technical, and highlight any required actions.

#### outage@ email template

```
Subject line: GPII [Scheduled/Completed/In progress] Production Outage - $start_date [- $end_date]

Body (plaintext please), dates in "Jan 14, 19:00 UTC" format:

What: What service(s) are affected
When: $start_date [-$end-date]
   * Announce an outage for ~2x the time you expect it to take. This allows some buffer if problems arise.
Status: [Scheduled/Completed/In progress]

Details:
Couple of lines explaining why this is planned, what is being done, and when
users can expect the next update. E.g., "The Ops team is currently
investigating the issue and we will update you once the cause is known/issue is
resolved/update is done.

[For planned downtime only]
If this downtime will be disruptive to your work ("We're giving a demo for the
Prime Minister at that time!"), please let me know immediately.
```
