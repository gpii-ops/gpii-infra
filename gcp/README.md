# gpii-infra GCP

This directory manages GPII infrastructure in [Google Cloud Project (GCP)](https://cloud.google.com/). It is organized as an [exekube](https://github.com/exekube/exekube) project and is very loosely based on the [exekube demo-apps-project](https://github.com/exekube/demo-apps-project)

Initial instructions based on [exekube's Getting Started](https://exekube.github.io/exekube/in-practice/getting-started/) (version 0.3.0).

## Install packages

1. Install Ruby **==2.4.3**.
   * There's nothing particularly special about this version. We could relax the constraint in Gemfile, but a single version for everyone is fine for now.
   * I like [rvm](https://rvm.io/) for ruby management.
   * If you're using a package manager, you may need to install "ruby-devel" as well.
1. Install [rake](https://github.com/ruby/rake) **==12.3.0**, probably via `gem install rake -v 12.3.0`.
1. Install [Docker](https://www.docker.com/get-started), and be sure that the **docker-compose** application is available at the command line.

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

## Creating the infrastructure

The environments that run in GCP need some initial resources that must be created by an administrator first. The [common part of this repository](../common) has the code and the instructions to do so.

## Permissions

The permissions in this project are set in three different levels: at organization level, at project level and at resource level.

At the organization level we have the group _cloud-admin@raisingthefloor.org_ which contains the list of users that will manage the projects of the organization and has the high level permissions to do so. Also we have a Service Account (SA) dedicated for the project creation and the billing association: _projectowner@gpii-common-prd.iam.gserviceaccount.com_. This SA only has the enough permissions to create projects, assciate them to the billing account and create the IAMs needed in such project to allow the owner to create the resources inside it. The SA _projectowner@gpii2test-common-stg.iam.gserviceaccount.com_ must also be in the organization level, as the billing account is associated to this organization and it is used to attach it to the testing organization _test1.gpii.net_.

Each project has a SA which performs almost all the actions over the resources of such project. This SA only has the permissions needed to deploy GPII cloud. This SA doesn't have permissions to make changes outside the project which owns it.

The permissions set at resource level are automaticallly set by Terraform in order to work properly among the rest of the components of the GPII cloud. i.e the storage bucket permissions for exported logs https://console.cloud.google.com/storage/browser/gpii-gcp-dev-alfredo-exported-logs?project=gpii-gcp-dev-alfredo

## Creating an environment

An environment needs some resources created in the organization before the following actions are done. Ask an operator of the organization to create a new project for such environment. In the case of a `dev` project the $USER environment variable is used to name the project. Provide such value to the operator. After the common part is created the following steps will spin up the cluster:

1. Clone this repo.
1. (Optional) Clone [the gpii-ops fork of exekube](https://github.com/gpii-ops/exekube).
   * The `gpii-infra` clone and the `exekube` clone should be siblings in the same directory (there are some references to `../exekube`). This is useful for testing the Terraform modules allocated in the exekube's project. If you want to have those modules in your exekube container uncomment the proper line in the docker-compose.yml file before running any command.
1. By default you'll use the RtF Organization and Billing Account.
   * You can use a different Organization or Billing Account, e.g. from a GCP Free Trial Account, with `export ORGANIZATION_ID=111111111111` and/or `export BILLING_ID=222222-222222-222222`.
1. In the case of using a **dev** environment, be sure that the environment variable `$USER` is set to the same name used to name your dev project at GCP. In case of doubt ask to the ops team.
1. `cd gpii-infra/gcp/live/dev`
1. `rake`
1. If it's the first time that you deploy the infrastructure you will be prompted to verify your identity at Google and allow permissions to your applications to perform modifications in your personal project at GCP. Go to the url shown and copy and paste the token once the application is authorized.
1. Once finished all the GPII endpoints should be available at `https://<service>.<your cluster name>.dev.gcp.gpii.net/`

   * e.g. http://preferences.alfredo.dev.gcp.gpii.net/preferences/carla
   * e.g. http://flowmanager.alfredo.dev.gcp.gpii.net

1. The dashboard is available through the [Google Cloud Console](https://console.cloud.google.com).

   Here it is a list of the common links:

   * [Storage](https://console.cloud.google.com/storage/browser)
   * [DNS zones](https://console.cloud.google.com/net-services/dns/zones)
   * [Kubernetes clusters](https://console.cloud.google.com/kubernetes/list)

   The dashboard also has a very good feature called [**Google Cloud Shell**](https://cloud.google.com/shell/docs/) which allows to have an interactive terminal embedded in the GCP dashboard. To use it just click on the icon that you will find at the top right, next to the magnifier icon.

   Once you have the shell on your browser execute the following lines to manage the Kubernetes cluster using the embedded *kubectl* command:

   1. `gcloud container clusters get-credentials k8s-cluster --zone us-central1`
   1. `kubectl -n gpii get pods`

   It's a Debian GNU/Linux so all the `apt` commands are also available.

   You can also upload/download files using such functionality that you will find in the top right menu of the interactive shell.

## Tearing down an environment

1. `rake destroy`
   * This is the important one since it shuts down the expensive bits (VMs in the Kubernetes cluster, mostly)
1. `rake destroy_infra`
   * Exekube recommends leaving these resources up since they are cheap
1. There's no automation for destroying the Project and starting over. I usually use the GCP Dashboard.
   * Note that "deleting" a Project really marks it for deletion in 30 days. You can't create a new Project with the same name until the old one is culled.
1. (OPTIONAL) `rake clean`
   * This command is optional, but it's recommended to run after a destroy. It will remove some temporal and cache files that can conflict in the case of an unfinished deployment.
1. (OPTIONAL) `rake clobber`
   * This command is also optional, but performs a deletion of some more files than `rake clean`, it will leave your personal environment without generated data. You will need to authenticate again the application in GCP after this.

## One-time Google Cloud Account Setup
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

## One-time CI Setup
1. Log in to the CI Worker and clone this repo.
1. `cd gpii-infra/ && rake -f rakefiles/ci_save_all.rake`


## Monitoring and alerting

We use [Stackdriver Beta Monitoring](https://cloud.google.com/monitoring/kubernetes-engine/) to collect various system metrics, navigate through them with [Kubernetes Dashboard](https://app.google.stackdriver.com/kubernetes), and send alerts when they violate thresholds that are being set by [Stackdriver Alerting Policies](https://app.google.stackdriver.com/policies).

Due to the lack of Terraform integration we use [Ruby client](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/modules/gcp-stackdriver-alerting/client.rb) to apply / update / destroy Stackdriver's resource primitives from their [json configs](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/modules/gcp-stackdriver-alerting/resources).

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
1. Run `TF_VAR_stackdriver_debug=1 rake deploy_module['k8s/stackdriver/alerting']`.
1. You will find json blobs for all supported Stackdriver resources in the output.
1. To add new resource config into `gcp-stackdriver-alerting` module:
   * Copy json blob that you obtained on previous step into proper [resource directory](https://github.com/gpii-ops/gpii-infra/blob/master/gcp/modules/gcp-stackdriver-alerting/resources). Give a meaningful name to a new resource file. You can use `jq` to help with formatting.
   * Remove all `name` attributes.
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

## FAQ / Troubleshooting

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
Solution is to `rake clobber` and re-authenticate.

### helm_release.release: rpc error: code = Unavailable desc = transport is closing

This caused by locally missing helm certificates (similarly to previous error, it usually happens when working to `stg` or `prd` environment, after `rake clobber`) and can be fixed by running `rake deploy_module['k8s/kube-system/helm-initializer']`.

### helm_release.release: error creating tunnel: "could not find tiller"

This some times happens during forceful cluster re-creation (for example when updating oauth scopes), and caused by Terraform failing to trigger `helm-initializer` module deployment.
Solution is to run `rake deploy_module['k8s/kube-system/helm-initializer']`.

### The metric referenced by the provided filter is unknown. Check the metric name and labels. (Google::Gax::RetryError)

This some times happens, when Stackdriver Ruby client is trying to apply alerting policy on newly created log-based metric. Solution is to wait 5-10 minutes and try again.

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

### Kubernetes resource requests and limits

* Use [resource requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) for components that run in Kubernetes.
   * Among their many benefits, Stackdriver needs resource requests and limits to generate meaningful Kubernetes dashboards.
* Memory: use the same value for Request and Limit. This makes scheduling in the cluster more predictable.
* CPU: favor using the same value for Request and Limit as this makes scheduling in the cluster more predictable.
   * However, to ease running resource-intensive components (CouchDB, Flowmanager, Preferences) in clusters with fewer resources (dev environments), you may set a component's CPU Request to a smaller value of the component's CPU Limit (e.g. `Request = 0.5 * Limit`).
* To determine initial values for a component's Requests and Limits:
   * Observe the component at idle and under some load.
   * Add a buffer for safety, e.g. `1.5 * observed value`.
* Favor specifying default Requests and Limits as far "down the stack" as possible, i.e. favor Chart defaults over Terraform module defaults over environment-specific settings.
