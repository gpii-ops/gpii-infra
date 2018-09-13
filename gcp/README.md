# gpii-infra GCP

This directory manages GPII infrastructure in [Google Cloud Project (GCP)](https://cloud.google.com/). It is organized as an [exekube](https://github.com/exekube/exekube) project and is very loosely based on the [exekube demo-apps-project](https://github.com/exekube/demo-apps-project)

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

## Creating the infrastructure

The environments that run in GCP need some initial resources that must be created by an administrator first. The [common part of this repository](../common) has the code and the instructions to do so.

## Creating an environment

An environment needs some resources created in the organization before the following actions are done. Ask an operator of the organization to create a new project for such environment. In the case of a `dev` project the $USER environment variable is used to name the project. Provide such value to the operator. After the common part is created the following steps will spin up the cluster:

1. Clone this repo.
1. (Optional) Clone [the gpii-ops fork of exekube](https://github.com/gpii-ops/exekube).
   * The `gpii-infra` clone and the `exekube` clone should be siblings in the same directory (there are some references to `../exekube`).
1. By default you'll use the RtF Organization and Billing Account.
   * You can use a different Organization or Billing Account, e.g. from a GCP Free Trial Account, with `export ORGANIZATION_ID=111111111111` and/or `export BILLING_ID=222222-222222-222222`.
1. `cd gpii-infra/gcp/live/dev`
1. `rake`

## Tearing down an environment

1. `rake destroy`
   * This is the important one since it shuts down the expensive bits (VMs in the Kubernetes cluster, mostly)
1. `rake destroy_infra`
   * Exekube recommends leaving these resources up since they are cheap
1. There's no automation for destroying the Project and starting over. I usually use the GCP Dashboard.
   * Note that "deleting" a Project really marks it for deletion in 30 days. You can't create a new Project with the same name until the old one is culled.

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

### Restoring CouchDB data

We are considering number of probable failure scenarios for our GCP infrastructure.
You can run all `kubectl` commands mentioned below inside of interactive shell started with `rake sh`.

1. **Data corruption on a single CouchDB replica**

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

2. **Data corruption on all replicas of CouchDB cluster**

There may be a situation, when we want to roll back entire DB data set to another point in the past. Current solution is disruptive, requires bringing entire CouchDB cluster down and some manual actions (we'll most likely automate this in future):

* Choose a snapshot set that you want to restore, make sure that snapshots are present for all disks that are currently in use by CouchDB cluster.
* Collect CouchDB volume names from PVCs with `kubectl --namespace gpii get pvc | grep database-storage-couchdb`.
* Get current number of CouchDB stateful set replicas with `kubectl --namespace gpii get statefulset couchdb-couchdb -o jsonpath="{.status.replicas}"`.
* Scale CouchDB stateful set to 0 replicas with `kubectl --namespace gpii scale statefulset couchdb-couchdb --replicas=0`. This will cause K8s to terminate all CouchDB pods, all PDs that were mounted into them will be released. **This will prevent flowmanager and preferences services from processing customer requests!**
   * You may also want to scale `flowmanager` and `preferences` deployments to 0 replicas as well with `kubectl --namespace gpii scale deployment preferences --replicas=0` and `kubectl --namespace gpii scale deployment flowmanager --replicas=0`. This will give you time to verify that DB restoration is successful before allowing the DB to receive traffic again.
* Destroy `k8s-snapshots` module with `rake destroy_module["k8s/kube-system/k8s-snapshots"]` to prevent new snapshots from being created while you working with disks.
* Open Google Cloud console, go to "Compute Engine" -> "Disks".
* Now, for every PD you collected:
   * Remember PD's name, type, size and zone.
   * Pick proper snapshot.
   * Delete PD.
   * Create new PD from snapshot with the same name, type, size and zone.
* Scale CouchDB stateful set back to number of replicas it used to have before with `kubectl --namespace gpii scale statefulset couchdb-couchdb --replicas=N`
* Database is now restored to the state at the time of target snapshot.
   * You can check the status of all nodes with `for i in {0..N}; do kubectl exec --namespace gpii -it couchdb-couchdb-$i -c couchdb -- curl -s http://$TF_VAR_secret_couchdb_admin_username:$TF_VAR_secret_couchdb_admin_password@127.0.0.1:5984/_up; done`, where N is a number of CouchDB replicas.
* Once DB state is verified and you sure that everything went as desired, you can scale `preferences` and `flowmanager` deployments back as well. From this point system functionality for the customer is fully restored.
* Deploy `k8s-snapshots` module to resume regular snapshot process with `rake deploy_module["k8s/kube-system/k8s-snapshots"]`.

## Design principles

* Favor pushing implementation "down the stack". The more we act like a "regular" Exekube project, the more we benefit from upstream improvements. Hence, favor Terraform code over in-line shell scripts over Ruby/Rake wrapper code.
   * Here is a [notable exception](https://github.com/gpii-ops/gpii-infra/pull/93/commits/5d307a373bd42505f066bb24f6686f107aed2728), where moving a calculation up to Ruby/Rake resulted in much simpler Terraform code.
