# gpii-infra AWS

Following the pattern laid out in "[How to create reusable infrastructure with Terraform modules](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d)" and "[Terragrunt: Remote Terraform configurations](https://github.com/gruntwork-io/terragrunt#keep-your-remote-state-configuration-dry)", this repo describes both the state of deployed infrastructure ("houses") and the modules ("blueprints") that comprise the [GPII](http://gpii.net/).

## Getting Started

### Install packages

**NOTE: Use exact versions for best results.** We have observed non-obvious problems from using even slightly different versions (especially terraform and kops).

Most MacOS users are looking for packages with names that contain `darwin_amd64` or `osx-amd64`. Most Linux users are looking for packages with names that contain `linux_amd64`.

1. Install [terraform](https://releases.hashicorp.com/terraform/) **==0.11.7**.
1. Install [terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt) **==0.14.0**.
1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) **==1.9.8**.
1. Install [kops](https://github.com/kubernetes/kops#installing) **==1.8.1**.
1. Install [Kubernetes Helm](https://github.com/kubernetes/helm#install) **==2.8.2**.
1. Install the [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) **==1.15.45**, possibly via `pip install awscli==1.15.45`.
   * The CI machine happens to use the listed version today. In practice, I haven't seen any trouble with versions including 1.11.129, 1.14.16, and 1.15.45.
1. Install Ruby **==2.4.3**.
   * There's nothing particularly special about this version. We could relax the constraint in Gemfile, but a single version for everyone is fine for now.
   * I like [rvm](https://rvm.io/) for ruby management.
   * If you're using a package manager, you may need to install "ruby-devel" as well.
1. Install [Bundler](http://bundler.io/) **==1.16.1**, probably via `gem install bundler -v 1.16.1`.
1. Install [rake](https://github.com/ruby/rake) **==12.3.0**, probably via `gem install rake -v 12.3.0`.
1. Install [jq](https://stedolan.github.io/jq/) **==1.5**.

### Configure cloud provider credentials

1. Get an AWS access key and secret key, as described [here](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html).
1. Configure AWS credentials:
   * _Recommended:_ Run `aws configure` per [the docs](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration). Fill in the access key and secret key you downloaded from Amazon. Leave the other prompts empty.
   * _Or:_ Manually configure `~/.aws` to look like the examples [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html).
1. Verify your AWS credential configuration: `aws sts get-caller-identity`

### Configure SSH

1. Place an SSH key you'd like to use at `~/.ssh/id_rsa.gpii-ci`
   * Make sure the file is owned by you with `600` permissions.
   * Using your own key is fine if all you want is to test your own personal dev cluster. However, remember that your "fake" key won't let you log into shared environments like `stg`, or allow other developers to ssh to your cluster's nodes. For those purposes, you'll need a copy of the "official" `id_rsa.gpii-ci` from `~deploy/.ssh` on `i40`.
   * This path is hardcoded into the code responsible for provisioning instances.
   * The configuration process could create user accounts (there is already ansible code in the `ops` repo to do this) but for now we'll use this shared key.
1. For ad-hoc debugging and ansible: `ssh-add ~/.ssh/id_rsa.gpii-ci`

### Provision an environment

#### Usual workflow

1. Clone this repo.
1. `cd` into the `gpii-infra/aws/dev/` directory.
1. `bundle install --path vendor/bundle`
1. `rake`
   * This will create an independent dev environment called `dev-$USER` and run tests.
1. When you are done with this environment: `rake destroy` and then `rake clobber`
1. To see a list of other commands you can try: `rake -T`
1. If something didn't work, see [Troubleshooting](#troubleshooting).

#### One-time setup per AWS billing account

Billing account means "the Raising the Floor account", not "the TylerRoscoe 'account' (really an IAM User)". Skip these steps if you are an RtF employee.

##### Remote state

1. Initialize an S3 bucket for kops remote state:
   * `aws s3api create-bucket --bucket gpii-kubernetes-state --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2`
   * `aws s3api put-bucket-versioning --bucket gpii-kubernetes-state --versioning-configuration Status=Enabled --region us-east-2`

##### EBS Volume encryption key

See https://github.com/ussjoin/gpii-backup-scripts#ec2-ebs-snapshot-replication, but this project never reached production.

##### Alerts and notifications

We use [Prometheus Alertmanager](https://github.com/prometheus/alertmanager), managed by [Prometheus Operator](https://github.com/coreos/prometheus-operator/) and some pieces from [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus), to handle alerts and notifications.

1. Create [Amazon SES credentials](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html).
   * Add the usernamd and password to [Gitlab](../CI-CD.md#configure-gitlab-secret-variables).
1. Create a dedicate Google Group (ours is `alerts@RtF`) to receive alerts and re-distribute them to Operations staff.
   * Remove public access.
   * Allow posts from the SES address you created above.
   * Subscribe on-call personnel to this list.
1. Create a Slack channel `#alerts` to receive alerts.
   * Create an Incoming WebHook.
   * Give it a name, description, and icon (I like the ambulance emoji :)).
   * Add the WebHook URL to [Gitlab](../CI-CD.md#configure-gitlab-secret-variables).
   * See also: https://www.robustperception.io/using-slack-with-the-alertmanager/

### Manual testing

#### The Kubernetes dashboard

1. Go to `https://api.<your cluster name>.gpii.net/ui`
   * First you will authenticate to the API server.
      * Login is `admin`.
      * Get the password from `rake display_admin_password`.
   * Then you will authenticate to the Dashboard itself.
      * Select `Token`.
      * Token is the password from `rake display_admin_password`.
1. Select a namespace in the in the "Namespace" dropdown in the left column (*not* the "Cluster `->` Namespaces" link). GPII developers likely want the `gpii` Namespace; infrastructure developers will likely want `All namespaces`.
1. Click "Workloads" for a good overview of what's happening in the cluster.

#### On the local machine

1. `KOPS_STATE_STORE=s3://gpii-kubernetes-state kops validate cluster`
   * Add `--name dev-mrtyler.gpii.net` if you have multiple clusters configured.
1. `kubectl get nodes --show-labels`
   * Add `--context dev-mrtyler.gpii.net` if you have multiple clusters configured.

#### On the remote machine

1. Configure ssh, as described in [Configure SSH](#configure-ssh).
1. `ssh admin@api.<your cluster name>` e.g. `ssh -i ~/.ssh/id_rsa.gpii-ci -o StrictHostKeyChecking=no admin@api.stg.gpii.net`
1. `sudo docker ps` to see that Kubernetes containers are running.
1. `/var/log/kube-apiserver.log` is a good place to look if things aren't working.
1. This [overview of how a Kubernetes cluster comes up when using kops](https://github.com/kubernetes/kops/blob/master/docs/boot-sequence.md) is helpful for low-level cluster debugging, e.g. "Why isn't my cluster coming up?!"

### Cleaning up

1. `cd` into the `gpii-infra/aws/dev/` directory.
1. `rake destroy`
1. `rake clobber`

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

## Continuous Integration / Continuous Delivery

See [CI-CD.md](../CI-CD.md)

## Troubleshooting / FAQ

* Currently, this system builds everything in `us-east-2`. When inspecting cloud resources manually (e.g. via the AWS web dashboard), make sure this region is selected.
* This system uses a lot of rapidly-evolving software. If a tool reports strange errors that look like incompatibilities, try downgrading to an earlier version. [ansible-gpii-ci-worker](https://github.com/idi-ops/ansible-gpii-ci-worker/) should always contain a working combination of versions -- see [defaults/main.yml](https://github.com/idi-ops/ansible-gpii-ci-worker/blob/master/defaults/main.yml)
* The system -- terraform and kops, e.g. -- stores various kinds of state in S3. All environments share a single Bucket, but have separate Keys (directories, basically). If you are manipulating this state directly (experts only! but sometimes needed, e.g. to recover from upgrading to a non-backward compatible version of Terraform), take care to only make changes to the Keys related to your environment. Modifying the Bucket will affect other developers' environments as well as shared environments like `prd`!

### Error acquiring the state lock

Terraform uses [DynamoDB](https://aws.amazon.com/dynamodb/) for locking. An easy way to orphan a lock is to `Ctrl+c` out of Terraform in the middle of an operation. The error looks like this:

```
Error locking state: Error acquiring the state lock: ConditionalCheckFailedException: The conditional request failed
        status code: 400, request id: FA9FPD3LLHMKMHPR4D7M73V303VV4KQNSO5AEMVJF66Q9ASUAAJG
Lock Info:
  ID:        c785778e-0b67-0bcf-88fd-8c03045a045b
  Path:      gpii-terraform-state/dev-mrtyler/k8s/terraform.tfstate
  Operation: OperationTypeApply
  Who:       mrtyler@somehost
  Version:   0.9.11
  Created:   2017-10-25 01:58:19.820236816 +0000 UTC
  Info:
```

To delete the lock:
1. **Make sure the lock is really orphaned!** This is especially important in shared environments like `stg` where CI or other developers could be making changes. The `Who` value in the error message gives you a clue about this.
1. Find the ID and Path from the error message (see above)
1. `rake "force_unlock[c785778e-0b67-0bcf-88fd-8c03045a045b, gpii-terraform-state/dev-mrtyler/k8s/terraform.tfstate]"`
1. You can also use the AWS web dashboard -- do this if you're recovering from a [messed up cluster](#my-cluster-is-messed-up-and-i-just-want-to-get-rid-of-it-so-i-can-start-over). Go to `DynamoDB -> Tables -> gpii-terraform-lock-table -> Items`. Select the lock(s) for your environment `-> Actions -> Delete`.

### My cluster is messed up and I just want to get rid of it so I can start over

1. `rake destroy` - the cleanest way to terminate a cluster. However, it may fail if the cluster never converged. If `rake` is spending a lot of time trying to undeploy components from a cluster that doesn't exist, `Ctrl+c` and continue to the next step.
1. `rake _destroy` - destroys cloud resources but does not undeploy GPII components. This can cause `_destroy` to get stuck: Rake and Terraform don't know about resources created by Kubernetes, such as load balancers. These Kubernetes-managed resources will block Terraform from deleting, e.g. the network in which the load balancer resides.
   * If `rake _destroy` gets stuck, it's best to let it finish/time out (to avoid [orphaning a DynamoDB lock](#error-acquiring-the-state-lock)) and continue to the next step. We'll run `rake _destroy` again later.
1. The AWS dashboard - I'm sorry that you're here, but the last step is manually deleting orphaned resources.
   * One helpful trick is to make a Classic Resource Group (top bar `->` Resource Groups `->` Create a Resource Group) and find resources Tagged with `KubernetesCluster: dev-mrtyler.gpii.net`. [Here is one I made for my dev environment](https://resources.console.aws.amazon.com/r/group#sharedgroup=%7B%22name%22%3A%22dev-mrtyler%22%2C%22regions%22%3A%22all%22%2C%22resourceTypes%22%3A%22all%22%2C%22tagFilters%22%3A%5B%7B%22key%22%3A%22KubernetesCluster%22%2C%22values%22%3A%5B%22dev-mrtyler.gpii.net%22%5D%7D%5D%7D).
   * Not all cloud resources are Taggable so you may need to explore a little, but the Resource Group report should give you an idea of what kinds of resources are getting stuck.
   * Use this order when manually deleting resources: Autoscaling Groups `->` Instances `->` Volumes `->` VPCs `->` Security Groups
      * Autoscaling Groups, Instances, and Volumes can be found on the "EC2 Dashboard".
      * VPCs and Security Groups can be found on: Top left menu Services `->` VPC `->` left side menu Your VPCs `->` delete all VPC `dev-mrtyler.gpii.net` (deleting a VPC deletes that VPC's Security Groups).
   * You can also use the new (non-Classic) Resource Group interface, though I find it more confusing than Classic Resource Groups:
      * Top bar `->` Resource Groups `->` Create a Resource Group.
      * Leave "Select resource types" dropdown alone.
      * "Tag key" is `KubernetesCluster`.
      * "Optional tag value" is `dev-mrtyler.gpii.net`.
      * Click "View group resources" above the filter fields.
1. The AWS dashboard, part 2 - various tools in the system store state in S3 and DynamoDB. If you encounter weird mismatch errors, you may need to perform more manual cleanup.
   * Check S3 Bucket `gpii-terraform-state` for Keys named after your environment (`dev-mrtyler.gpii.net`) and delete only those keys.
   * Repeat in subdirectory `prereqs`.
   * Check S3 Bucket `gpii-kubernetes-state` for Keys named after your environment (`dev-mrtyler.gpii.net`) and delete only those keys.
   * Check DynamoDB for orphaned locks. See [Error acquiring the state lock](#error-acquiring-the-state-lock).
1. The AWS dashboard, part 3 - Route 53 DNS (Services `->` search for Route 53)
   * Go to "Hosted zones".
   * Delete the zone for your cluster (e.g. `dev-mrtyler.gpii.net.`).
   * Go to the hosted zone `gpii.net`.
   * Delete the `NS` record for your cluster (e.g. `dev-mrtyler.gpii.net.`).
1. Other stuff - a few more things to clean if you're still having problems.
   * Check for orphaned IAM Roles using the AWS dashboard (Services `->` search for IAM `->` Roles) and delete them.
   * Delete `$TMPDIR/rake-tmp` (`rake clobber` should take care of this but just in case).
   * Delete `~/.terraform.d` from your home directory.
   * Delete any directories in your `gpii-infra/aws` directory named `.bundle` or `.terraform` (`find aws/ -name '*.bundle' -o -name '*.terraform'`).
1. Run `rake _destroy` again to make sure Terraform agrees that all the old resources are gone and to clean up DNS entries.
1. `rake clobber` - cleans up generated files.

### The Job "gpii-dataloader" is invalid

When re-deploying `gpii-dataloader` (e.g. running `rake` against an already existing cluster), the following error is expected and harmless:
```
The Job "gpii-dataloader" is invalid: spec.template: Invalid value: api.PodTemplateSpec{... lots of stuff ...}: field is immutable
```

See also [A note about local changes and gpii-dataloader](#a-note-about-local-changes-and-gpii-dataloader)

### Running manually in non-dev environments (stg, prd)

See [CI-CD.md#running-in-non-dev-environments](../CI-CD.md#running-manually-in-non-dev-environments-stg-prd)

### I want to test my local changes to GPII components in my cluster

1. Build a local Docker image containing your changes.
1. Push your image to Docker Hub under your user account.
1. Clone https://github.com/gpii-ops/gpii-version-updater/.
1. Edit `components.conf`. Find your component and edit the `image` field to point to your Docker Hub user account.
   * E.g., `gpii/universal -> mrtyler/universal`
1. Run `update-version`. It will generate a `version.yml` in the current directory.
1. `cp version.yml ../gpii-infra/modules/deploy`
1. `cd ../gpii-infra/aws/dev && rake deploy`

#### Can't I just edit `version.yml` by hand?

gpii-infra uses explicit SHAs to refer to specific Docker images for GPII components. This has a number of advantages (repeatability, auditability) but the main thing you care about is that changing the SHA forces Kubernetes to re-deploy a component (but see below for a note about gpii-dataloader).

If you don't want to deal with gpii-version-updater, you can instead:
1. Edit `modules/deploy/version.yml`. Find your component and replace the entire image value (path and SHA) with your Docker Hub user account.
   * E.g., `flowmanager: "gpii/universal@sha256:4b3...64f" -> flowmanager: "mrtyler/universal"`
1. Manually delete the component via Kubernetes Dashboard or `kubectl delete`.
1. `cd aws/dev && rake deploy`

#### A note about local changes and gpii-dataloader

[gpii-dataloader](https://github.com/gpii-ops/gpii-dataloader) initializes CouchDB with some canned data. It is designed to run once, as a Kubernetes Job. If you want to run it again, e.g. to test changes to the canned data:
1. Note that the dataloader **deletes all data in CouchDB** when it runs.
1. Because of how Kubernetes Jobs work, the dataloader will not re-run when a new Docker image becomes available (this is different from Deployments like `flowmanager`, which are updated when the Docker image changes).
1. Thus, to make changes to the dataloader:
   * Delete the Job: `kubectl -n gpii delete job gpii-dataloader`
   * Re-deploy the Job: `cd aws/dev && rake deploy`
1. We abuse the fact that Kubernetes doesn't allow a Job's Docker image to be changed to prevent the dataloader Job from running (and deleting all data from CouchDB) every time. See [The Job "gpii-dataloder" is invalid](#the-job-gpii-dataloader-is-invalid) and [this architecture@ thread](https://lists.gpii.net/pipermail/infrastructure/2017-September/000070.html).


### Restoring a volume from a backup/snapshot

1. We use [k8s-snapshots](https://github.com/miracle2k/k8s-snapshots) to periodically snapshot Kubernetes Persistent Volumes.
1. If you are reading this because of a **real outage**:
   * I'm sorry :( but know that everything will be ok! :)
   * Consider when to shut down the affected resources:
      * Waiting reduces downtime and may be a better choice if you will perform surgery to merge data accrued after the Snapshot was created.
      * Doing it now reduces the potential delta between the existing Volumes and the new Volumes from Snapshots, but increases downtime.
1. If you're ready, delete all affected resources so that the component stops using the old Volumes: Kubernetes Dashboard `->` Workloads (or whatever) `->` (find in list) `->` ... Menu on right `->` Delete. Or, use `kubectl delete`.
   * At this point, the **health of the cluster will be impacted** until it re-converges with the new Volumes in place.
   * Affected resources include anything that touches the Volumes:
      * The Persistent Volumes and Persistent Volume Claims associated with the Volumes
         * Delete these first so that anything relying on the Volumes won't re-attach to the old Volumes before the new ones are in place.
      * The StatefulSet or Deployment that manage the Pods that are attached to the Volumes
         * Note that if you just delete a Pod, the StatefulSet or Deployment will respawn it automatically.
1. Find the Snapshot or set of Snapshots you want to restore: AWS Dashboard `->` EC2 `->` Snapshots.
   * For clusters that replicate data (e.g. couchdb), we must restore all of the Volumes together. Otherwise, the cluster will perceive the new Volume as being out-of-date from the old Volumes and will sync (bad) data to the new Volume.
   * For "clusters" that don't replicate data (e.g. prometheus), we may wish to restore all of the Volumes together anyway to prevent inconsistency (e.g. Grafana graphs may be inconsistent if the backing Prometheus databases are out-of-sync).
1. Create a new Volume from each Snapshot: Select Snapshot `->` Actions `->` Create Volume.
   * Most defaults should be correct.
   * Make sure to create the new Volume in the **same Availability Zone** as the old Volume.
   * Don't worry about changing Name or other Tags. Terraform will add them shortly.
   * Note the Volume ID of the new Volume.
1. For clarity, rename the old Volume. Prepend something like `REPLACED WITH vol-ffedcba BY MRTYLER 2017-10-06`.
1. Determine the name of the component associated with this volume (e.g. `couchdb` for couchdb, `prometheus` for prometheus). Consult [modules/volume/vars.tf](modules/volume/vars.tf) if you're unsure.
1. In the appropriate environment directory: `rake "import_volume[some-component, vol-0123456789abcdeff, us-east-9z]"`.
   * Use the new Volume ID from earlier.
   * Use the Availability Zone you selected earlier.
1. If you haven't yet deleted affected resources, delete them now (see above).
1. Run `rake` in the appropriate environment directory (e.g `dev`) to re-deploy the resources you just deleted.
1. Relaunch k8s-snapshots (delete the Pod and let the Replica Set respawn it). It will continue to back up the old Volume (and fail to back up the new Volume) until you do.
1. Snapshots for the old Volume will not be expired automatically. They will need to be managed by hand.

#### Hack: Adding data to CouchDB

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

### Increasing the size of a volume

Uh-oh, the Persistent Volumes that back the database are getting full (or need more provisioned IOPS, or some other change to the configuration of the underlying Volume)!

1. [This Amazon article](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-modify-volume.html) outlines the basic strategy.
1. Our Persistent Volumes are managed by Terraform. Change the size there.
1. Our Persistent Volume Claims are managed in `modules/deploy/`. Make changes there to match the changes in the Terraform code.
1. `rake apply` to test in your dev environment. Commit and push and let CI make the change to other environments.
1. Next we need to convince the running Node that the size has changed.
   * An easy way is rebooting the Node. Depending on spare capacity in the Kubernetes cluster, this action is somewhat to very disruptive.
   * Slightly slower and more labor intensive is [draining the Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/) and then rebooting it. If there is adequate capacity in the Kubernetes cluster, this action is mostly non-disruptive for users although Pods will be restarted. If there is not adequate capcity, this action is still very disruptive.
   * A very non-invasive but somewhat manual approach is described below.
1. `ssh` to each Node running a component affected by the Volume size change (e.g. CouchDB Pods or Prometheus Pods). The Kubernetes Dashboard, or `kubectl describe pod` and `kubectl describe node`, are helpful to discover where things are running.
1. `lsblk` to verify that the block device itself reflects the updated size.
1. Use the mounted path from `lsblk` above to verify the Pod is still seeing the old size: `sudo df -h /var/lib/kubelet/pods/fd14a296-e8c4-11e7-a320-02402b50a7f8/volumes/kubernetes.io~aws-ebs/prometheus-us-east-2c-pv`
1. `growpart`, as recommended in the Amazon article above, does not work -- it insists on a partition number even though the provided block device (e.g. `/dev/xvdbw`) is itself a partition containing a filesystem (as you may verify with `file -s`).
1. Force the mounted volume to re-calculate size: `sudo resize2fs /dev/xvdbg`
1. Verify the Pod is now seeing the new size: `sudo df -h /var/lib/kubelet/pods/fd14a296-e8c4-11e7-a320-02402b50a7f8/volumes/kubernetes.io~aws-ebs/prometheus-us-east-2c-pv`
1. It may be necessary to restart Pods to force them to notice the new size (Prometheus seems to need this once it has filled a disk). Use the Dashboard or `kubectl delete pod`.

### I want to work on a different dev cluster

**Note: this is an advanced / non-standard workflow.** There aren't a lot of guard rails to prevent you from making a mistake. User discretion is advised.

Examples of when you might want to do this:
* (Most common) Cleaning up when CI ends up with a broken `dev-gitlab-runner` cluster, e.g. the CI server reboots and orphans a Terraform lock.
* Collaborating with another developer in their dev cluster.
* Running multiple personal dev clusters (e.g. `dev-mrtyler-experiment1`).

1. Prepend `USER=gitlab-runner TF_VAR_environment=dev-gitlab-runner` to all `rake` commands.
   * Or, to add an additional dev cluster: `USER=mrtyler-experiment1 TF_VAR_environment=dev-mrtyler-experiment1`
   * `TF_VAR_environment` must contain `USER` as above. Otherwise, behavior is undefined.

### I want to change Grafana dashboards or Alertmanager alerts [experimental]

The manifests that control Grafana dashboards and Alertmanager alerts are copied from [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) and then modified locally (e.g. a few more things in the `monitoring` namespace, different Service types).

#### I want to update to the latest kube-prometheus

Unfortunately, there's not a good automatic migration path. So I do this:

1. From a clone of the prometheus-operator repo, `git log -p 6beaec7a.. -- contrib/kube-prometheus/manifests` to see what has changed.
1. For any changed files, copy the manifest from kube-prometheus to the appropriate manifest in `modules/deploy` (the filenames are similar but slightly different).
1. Review `git diff` to make sure no local changes will be clobbered.
1. Update the `git log -p` argument above to reflect where the next updater should start looking.
1. `git commit`. In your log message, include the revision you pulled from upstream `kube-prometheus`.

### I accidentally deleted my kops state from S3 [experimental]

**Note: this is an advanced workflow and it is incomplete.** User discretion is advised.

`kops` stores state in S3, so if you delete your cluster's entry in `s3://gpii-kubernetes-state`, you will be unable to use Kubernetes commands (`kops`, `kubectl`) to interact with your cluster. Thanks to S3 Bucket Versioning, you can recover from this by undeleting your cluster's folder (`s3://gpii-kubernetes-state/dev-mrtyler.gpii.net`).

Here is an example that needs customization. Some notes:
   * Inspired by [How to Undelete Files in Amazon S3](http://www.dmuth.org/node/1472/how-undelete-files-amazon-s3)
   * The `grep '\tTrue'` is to find the latest version (in this case, the most recently deleted version) of a file
   * The `grep` for datestamp limits the undelete to the last set of files that were deleted. This avoids undeleting really old files with slightly different auto-generated names (e.g. `6474602931679620185804047508.crt`).

```
aws \
  --region us-east-2 \
  s3api list-object-versions \
  --bucket gpii-kubernetes-state \
  --prefix dev-mrtyler.gpii.net/ \
  --output text \
  | grep '\tTrue' \
  | grep '\t2017-11-06T19' \
  | awk \
  '{print "aws --region us-east-2 s3api delete-object --bucket gpii-kubernetes-state --key """$3""" --version-id """$5""""}' \
  > undelete.sh
sh undelete.sh
```

## History

This repo is the union of two older repos: [gpii-terraform-modules](https://github.com/mrtyler/gpii-terraform-modules) (formerly called `gpii-terraform`) and [gpii-terraform-live](https://github.com/mrtyler/gpii-terraform-live). I (@mrtyler) did not retain history when merging these two repos. Please refer to the above repos for archaeological expeditions.
