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

### Enable Multi-Factor Authentication (MFA) on your account

* From [Google 2-Step Verification](https://www.google.com/landing/2step/), click Get Started and follow the prompts.
   * I like [Duo](https://duo.com/product/trusted-users/two-factor-authentication/duo-mobile), but any tool from [Amazon's list](https://aws.amazon.com/iam/details/mfa/) should be fine. See also [Google's documentation](https://www.google.com/landing/2step/).
   * (If you don't have access to a separate device for MFA (smartphone, tablet, hardware device such as a Yubikey), it is acceptable (though not recommended -- especially for administrators) to run an MFA tool on your development machine. A few of us like [Authy](https://authy.com/download/).

### Creating an environment

1. Clone this repo.
1. `cd gpii-infra/gcp/live/dev`
1. `rake`
   * The first time you deploy a GPII Cloud (or after you run `rake clobber`), you will be prompted to authenticate **twice**. Follow the instructions in the prompts.
   * If your browser is configured with multiple Google accounts (e.g. a personal Gmail account as well as an RtF Gmail account), make sure to choose the right one when authenticating.
1. Once `rake` finishes, GPII Cloud endpoints should be available at `https://<service>.<your cluster name>.dev.gcp.gpii.net/`
   * e.g. https://preferences.alfredo.dev.gcp.gpii.net/preferences/carla
   * e.g. https://flowmanager.alfredo.dev.gcp.gpii.net
1. Lots of information about your GPII Cloud is available through the [Google Cloud Console](https://console.cloud.google.com). Some common links:
   * [Kubernetes clusters](https://console.cloud.google.com/kubernetes/list)
   * [Logs](https://console.cloud.google.com/logs/viewer)
   * [Monitoring, metrics, and alerts](https://app.google.stackdriver.com/)
   * [Storage](https://console.cloud.google.com/storage/browser)
1. To see a list of other commands you can try: `rake -T`
1. If something didn't work, see [Troubleshooting / FAQ](#troubleshooting-faq).

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
1. The [Google Cloud Console](https://console.cloud.google.com) includes [Google Cloud Shell](https://cloud.google.com/shell/docs/) which is an interactive terminal embedded in the GCP dashboard. To use it, click on the icon at the top right of the Console, next to the magnifier icon.
   * Once the shell opens in your browser, execute the following to manage the Kubernetes cluster using the embedded `kubectl` command: 
   1. `gcloud container clusters get-credentials k8s-cluster --zone us-central1` (or whatever your `zone` is)
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

These are ephemeral environments, generally used by individual developers when working on the `gpii-infra` codebase or on cloud-based GPII components. An early phase of CI creates an ephemeral environment (`dev-gitlab-runner`) for integration testing.

### stg

This is a shared, long-lived environment for staging / pre-production. It aims to emulate `prd`, the production environment, as closely as possible.

Deploying to `stg` verifies that the gpii-infra code that worked to create a `dev-$USER` environment from scratch also works to update a pre-existing environment. This is important since we generally don't want to destroy and re-create the production environment from scratch.

Because `stg` emulates production, it will (in the future) allow us to run realistic end-to-end tests before deploying to `prd`.

### prd

This is the production environment which supports actual users of the GPII.

Deploying to `prd` requires a [manual action](https://docs.gitlab.com/ce/ci/yaml/#manual-actions). This enables automated testing (CI) and a consistent deployment process (CD) while providing finer control over when changes are made to production (e.g. on a holiday weekend when no engineers are around).

## Troubleshooting / FAQ

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

This caused by locally missing helm certificates (similarly to previous error, it usually happens when working to `stg` or `prd` environment, after `rake clobber`) and can be fixed by running `rake deploy_module['k8s/kube-system/helm-initializer']`.

### helm_release.release: error creating tunnel: "could not find tiller"

This some times happens during forceful cluster re-creation (for example when updating oauth scopes), and caused by Terraform failing to trigger `helm-initializer` module deployment.
Solution is to run `rake deploy_module['k8s/kube-system/helm-initializer']`.

### The metric referenced by the provided filter is unknown. Check the metric name and labels. (Google::Gax::RetryError)

This some times happens, when Stackdriver Ruby client is trying to apply alerting policy on newly created log-based metric. Solution is to wait 5-10 minutes and try again.

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

Manual workspace configuration is required in case you never used Stackdriver in your project before.

1. Go to [Stackdriver Monitoring Overview](https://app.google.stackdriver.com), you will be redirected to Project Setup page if needed.
1. Select "Create a new Workspace". Click "Continue".
1. Make sure that you see your project id under "Google Cloud Platform project". Click "Create workspace".
1. Make sure that only your project is selected under "Add Google Cloud Platform projects to monitor". Click "Continue".
1. Click "Skip AWS Setup".
1. Click "Continue".
1. Select desired reports frequency under "Get Reports by Email". Click "Continue".
1. Finished initial collection! Click "Launch Monitoring".

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

## Restoring CouchDB data

We are considering number of probable failure scenarios for our GCP infrastructure.
You can run all `kubectl` commands mentioned below inside of interactive shell started with `rake sh`.

### Data corruption on a single CouchDB replica

In this scenario we rely on CouchDB ability to recover from loss of one or more replicas (our current production CouchDB settings allow us to lose up to 2 random nodes and still keep data integrity). The best course of action as follows:

* Make sure that you figured affected CouchDB pod properly
* There is a PVC object, associated with affected CouchDB pod. Let's say affected pod is `couchdb-couchdb-1`, then corresponding PVC is `database-storage-couchdb-couchdb-1`, located in the same namespace.
* Delete associated PVC and then affected pod. For our example case:
   * `kubectl --namespace gpii delete pvc database-storage-couchdb-couchdb-1`
   * `kubectl --namespace gpii delete pod couchdb-couchdb-1`
* After target pod is terminated, Persistent Disk that was mounted into it thru corresponding PVC will be destroyed as well.
* When new pod is created to replace deleted one, corresponding PVC will be created as well, and, thru it, new PV object for new GCE PD.
* Run `rake deploy_module[couchdb]` to patch newly created PV with annotations for `k8s-snapshots`.
* CouchDB cluster will replicate data to recreated node automatically.
* Corrupted node is now recovered.
   * You can check DB status on recovered node with `kubectl exec --namespace gpii -it couchdb-couchdb-N -c couchdb -- curl -s http://$TF_VAR_couchdb_admin_username:$TF_VAR_couchdb_admin_password@127.0.0.1:5984/gpii/`, where N is node index.

### Data corruption on all replicas of CouchDB cluster

There may be a situation, when we want to roll back entire DB data set to another point in the past. Current solution is disruptive, requires bringing entire CouchDB cluster down and some manual actions (we'll most likely automate this in future):

* Choose a snapshot set that you want to restore, make sure that snapshots are present for all disks that are currently in use by CouchDB cluster.
* Collect CouchDB disk names from PVCs with `kubectl --namespace gpii get pvc -l app=couchdb -o json | jq -r .items[].spec.volumeName`.
* Get current number of CouchDB stateful set replicas with `kubectl --namespace gpii get statefulset couchdb-couchdb -o jsonpath="{.status.replicas}"`.
* Scale CouchDB stateful set to 0 replicas with `kubectl --namespace gpii scale statefulset couchdb-couchdb --replicas=0`. This will cause K8s to terminate all CouchDB pods, all PDs that were mounted into them will be released. **This will prevent flowmanager and preferences services from processing customer requests!**
   * You may also want to scale `flowmanager` and `preferences` deployments to 0 replicas as well with `kubectl --namespace gpii scale deployment preferences --replicas=0` and `kubectl --namespace gpii scale deployment flowmanager --replicas=0`. This will give you time to verify that DB restoration is successful before allowing the DB to receive traffic again.
* Destroy `k8s-snapshots` module with `rake destroy_module["k8s/kube-system/k8s-snapshots"]` to prevent new snapshots from being created while you working with disks.
* Open Google Cloud console, go to "Compute Engine" -> "Disks".
* Now, repeat for every CouchDB disk name you collected:
   * Save disk name, type, size, zone and description.
   * Pick proper snapshot.
   * Delete PD.
   * Create new PD from snapshot with the same name, type, size, zone and description.
* Scale CouchDB stateful set back to number of replicas it used to have before with `kubectl --namespace gpii scale statefulset couchdb-couchdb --replicas=N`
* Database is now restored to the state at the time of target snapshot.
   * You can check the status of all nodes with `for i in {0..N}; do kubectl exec --namespace gpii -it couchdb-couchdb-$i -c couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/_up; done`, where N is a number of CouchDB replicas.
* Once DB state is verified and you sure that everything went as desired, you can scale `preferences` and `flowmanager` deployments back as well. From this point system functionality for the customer is fully restored.
* Deploy `k8s-snapshots` module to resume regular snapshot process with `rake deploy_module["k8s/kube-system/k8s-snapshots"]`.

## Design principles

* Favor pushing implementation "down the stack". The more we act like a "regular" Exekube project, the more we benefit from upstream improvements. Hence, favor Terraform code over in-line shell scripts over Ruby/Rake wrapper code.
   * Here is a [notable exception](https://github.com/gpii-ops/gpii-infra/pull/93/commits/5d307a373bd42505f066bb24f6686f107aed2728), where moving a calculation up to Ruby/Rake resulted in much simpler Terraform code.

## Operational principles

* Avoid deploying changes near the end of your work day.
* Avoid deploying on Friday or prior to a holiday.
* Create JIRA tickets for issues (mainly CI/CD) we encounter and fix - to track the
  work done and to have data for future reference.

### Kubernetes resource requests and limits

* Use [resource requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) for components that run in Kubernetes.
   * Among their many benefits, Stackdriver needs resource requests and limits to generate meaningful Kubernetes dashboards.
* Memory: use the same value for Request and Limit. This makes scheduling in the cluster more predictable.
* CPU: favor using the same value for Request and Limit as this makes scheduling in the cluster more predictable.
   * However, to ease running resource-intensive components (CouchDB, Flowmanager, Preferences) in clusters with fewer resources (dev environments), you may set a component's CPU Request to a smaller value of the component's CPU Limit (e.g. `Request = 0.5 * Limit`).
* To determine initial values for a component's Requests and Limits:
   * Observe the component at idle and under some load, e.g. by running Locust tests against the component or environment.
   * Add a buffer for safety, e.g. `1.5 * observed value`.
* Favor specifying default Requests and Limits as far "down the stack" as possible, i.e. favor Chart defaults over Terraform module defaults over environment-specific settings.

### Docker images

We should be well-aware of Docker images we use in our infrastructrue, as deploying an untrusted, potentially malicious, image poses a significant security threat.

As a rule of thumb: official Docker curated images (https://docs.docker.com/docker-hub/official_images/) or images directly published by trusted OSS projects are acceptable, otherwise we should build the images ourselves.

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
```
