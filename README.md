# gpii-infra

Following the pattern laid out in "[How to create reusable infrastructure with Terraform modules](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d)" and "[Terragrunt: Remote Terraform configurations](https://github.com/gruntwork-io/terragrunt#keep-your-remote-state-configuration-dry)", this repo describes both the state of deployed infrastructure ("houses") and the modules ("blueprints") that comprise the [GPII](http://gpii.net/).

## Getting Started

### Install packages

1. Install [terraform](https://releases.hashicorp.com/terraform/) **< 0.10** (0.10 has significant architectural changes so I'm waiting on this (non backward-compatible) upgrade; also, kitchen-terraform doesn't support 0.10 yet).
1. Install [terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt) **< 0.13** (0.13.0 doesn't work with terraform < 0.10 yet).
1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
1. Install [kops](https://github.com/kubernetes/kops#installing) **>= 1.7.1** (< 1.7.0 has a security vulnerability in dnsmasq).
1. Install the [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html).
1. Install Ruby and [Bundler](http://bundler.io/) (for [kitchen](https://github.com/test-kitchen/test-kitchen) and [kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform)).
   * I like [rvm](https://rvm.io/) for ruby management.
   * If you're using a package manager, you may need to install "ruby-devel" as well.
1. Install [rake](https://github.com/ruby/rake), probably via `gem install rake`.
1. Install [jq](https://stedolan.github.io/jq/).

### Configure cloud provider credentials

1. Get an AWS access key and secret key, as described [here](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html).
1. Configure AWS credentials:
   * _Recommended:_ Run `aws configure` per [the docs](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration). Fill in the access key and secret key you downloaded from Amazon. Leave the other prompts empty.
   * _Or:_ Manually configure `~/.aws` to look like the examples [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html).
1. Verify your AWS credential configuration: `aws sts get-caller-identity`

### Configure SSH

1. Get a copy of `id_rsa.gpii-ci` from `~deploy/.ssh` on `i40`. Put it at `~/.ssh/id_rsa.gpii-ci`.
   * The destination path is hardcoded into `.kitchen.yml` and the code responsible for provisioning instances.
   * The configuration process could create user accounts (there is already ansible code in the `ops` repo to do this) but for now we'll use this shared key.
1. For ad-hoc debugging and ansible: `ssh-add ~/.ssh/id_rsa.gpii-ci`

### Provision an environment

1. The first time this is run in a given AWS account, you will need to initialize an S3 bucket for remote state for kops:
   * `aws s3api create-bucket --bucket gpii-kubernetes-state --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2`
   * `aws s3api put-bucket-versioning --bucket gpii-kubernetes-state --versioning-configuration Status=Enabled --region us-east-2`
1. Clone this repo.
1. `cd` into the `gpii-infra/dev/` directory.
1. `bundle install --path vendor/bundle`
1. `rake`
   * This will create an independent dev environment called `dev-$USER` and run tests.
1. When you are done with this environment: `rake destroy` and then `rake clobber`
1. To see a list of other commands you can try: `rake -T`
1. If something didn't work, see [Troubleshooting](#troubleshooting).

### Manual testing

#### The Kubernetes dashboard

1. Go to `https://api.<your cluster name>.gpii.net/ui`
   * Login is `admin`.
   * Get the password from `rake display_admin_password`.
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

1. `cd` into the `gpii-infra/dev/` directory.
1. `rake destroy`
1. `rake clobber`

## Troubleshooting

* Currently, this system builds everything in `us-east-2`. When inspecting cloud resources manually (e.g. via the AWS web dashboard), make sure this region is selected.
* This system uses a lot of rapidly-evolving software. If a tool reports strange errors that look like incompatibilities, try downgrading to an earlier version. [ansible-gpii-ci-worker](https://github.com/idi-ops/ansible-gpii-ci-worker/) should always contain a working combination of versions -- see [defaults/main.yml](https://github.com/idi-ops/ansible-gpii-ci-worker/blob/master/defaults/main.yml)
* The system -- terraform and kops, e.g. -- stores various kinds of state in S3. All environments share a single Bucket, but have separate Keys (directories, basically). If you are manipulating this state directly (experts only! but sometimes needed, e.g. to recover from upgrading to a non-backward compatible version of Terraform), take care to only make changes to the Keys related to your environment. Modifying the Bucket will affect other developers' environments as well as shared environments like `prd`!

### Error acquiring the state lock

Terraform uses [DynamoDB](https://aws.amazon.com/dynamodb/) for locking. An easy way to orphan a lock is to Ctrl-C out of Terraform in the middle of an operation. The error looks like this:

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
1. You can also use the AWS web dashboard. Go to `DynamoDB -> Tables -> gpii-infra-lock-table -> Items`. Select the lock(s) for your environment `-> Actions -> Delete`.

### My cluster is messed up and I just want to get rid of it so I can start over

1. `rake destroy` - the cleanest way to terminate a cluster. However, it may fail if the cluster never converged.
1. `rake _destroy` - destroys cloud resources but does not undeploy GPII components. This can cause `_destroy` to get stuck: Rake and Terraform don't know about resources created by Kubernetes, such as load balancers. These Kubernetes-managed resources will block Terraform from deleting, e.g. the network in which the load balancer resides.
1. The AWS dashboard - I'm sorry that you're here, but the last step is manually deleting orphaned resources.
   * One helpful trick is to make a Resource Group (top bar `->` Resource Groups `->` Create a Resource Group) and find resources Tagged with `KubernetesCluster: dev-mrtyler.gpii.net`. [Here is one I made for my dev environment](https://resources.console.aws.amazon.com/r/group#sharedgroup=%7B%22name%22%3A%22dev-mrtyler%22%2C%22regions%22%3A%22all%22%2C%22resourceTypes%22%3A%22all%22%2C%22tagFilters%22%3A%5B%7B%22key%22%3A%22KubernetesCluster%22%2C%22values%22%3A%5B%22dev-mrtyler.gpii.net%22%5D%7D%5D%7D).
   * Not all cloud resources care Taggable so you may need to explore a little, but the Resource Group report should give you an idea of what kinds of resources are getting stuck.
   * Eventually, I plan to add a `rake exterminate` to automate the destruction of wayward resources.
1. The AWS dashboard, part 2 - various tools in the system store state in S3 and DynamoDB. If you encounter weird mismatch errors, you may need to perform more manual cleanup.
   * Check S3 Bucket `gpii-infra-state` for Keys named after your environment (`dev-mrtyler.gpii.net`) and delete only those keys. Remember to check non-environment subdirectories like `prereqs`.
   * Check S3 Bucket `gpii-kubernetes-state` for Keys named after your environment (`dev-mrtyler.gpii.net`) and delete only those keys.
   * Check DynamoDB for orphaned locks. See section in [Troubleshooting](#troubleshooting).
1. Other stuff - a few more things to clean if you're still having problems.
   * Check for orphaned IAM Roles using the AWS dashboard and delete them.
   * Delete `$TMPDIR/rake-tmp` (`rake clobber` should take care of this but just in case).
   * Delete `~/.terraform.d` and any directories in your `gpii-infra` sandbox named `.bundle`, `.kitchen`, or `.terraform`.

#### After everything is cleaned up

1. Run `rake _destroy` again afterwards to make sure Terraform agrees that all the old resources are gone and to clean up DNS entries.
1. `rake clobber` - cleans up generated files.

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
1. Find the set of Snapshots you want to restore: AWS Dashboard `->` EC2 `->` Snapshots.
   * We must restore all of the Volumes together. Otherwise, the cluster will perceive the new Volume as being out-of-date from the old Volumes and will sync (bad) data to the new Volume.
1. Create a new Volume from each Snapshot: Select Snapshot `->` Actions `->` Create Volume.
   * Most defaults should be correct.
   * Make sure to create the new Volume in the **same Availability Zone** as the old Volume.
   * Don't worry about changing Name or other Tags. Terraform will add them shortly.
   * Note the Volume ID of the new Volume.
1. For clarity, rename the old Volume. Prepend something like `REPLACED WITH vol-ffedcba BY MRTYLER 2017-10-06`.
1. Determine the name of the component associated with this volume (e.g. `couchdb` for couchdb, `prometheus` for prometheus). Consult [modules/volume/vars.tf](modules/volume/vars.tf) if you're unsure.
1. In the appropriate environment directory: `rake "import_volume[couchdb, vol-0123456789abcdeff, us-east-9z]"`.
   * Use the new Volume ID from earlier.
   * Use the Availability Zone you selected earlier.
1. If you haven't deleted affected resources yet, delete them now (see above).
1. Run `rake` in the appropriate environment directory to re-deploy the resources you just deleted.
1. Relaunch the k8s-snapshots Pod (delete and let the Replica Set respawn it). It will continue to back up the old Volume (and fail to back up the new Volume) until you do.
1. Snapshots for the old Volume will not be expired automatically. They will need to be managed by hand.

#### Hack: Adding data to CouchDB

This is what I used to create a fake preference while verifying that volumes are restored correctly.

1. Run a container inside the cluster: `kubectl run -i -t alpine --image=alpine --restart=Never`
1. From inside the container, install some tools: `apk update && apk add curl`
1. Define a record:
```
# copied and modified from vicky.json
data='
{
  "_id": "tyler",
  "value": {
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
  }
}
'
```
1. Add the record: `curl -f -H 'Content-Type: application/json' -X POST http://couchdb.default.svc.cluster.local:5984/preferences -d "$data"`
1. Before the restore: verify that the new record is present.
1. After the restore: verify that the new record is no longer present.

### I want to work on a different dev cluster

**Note: this is an advanced / non-standard workflow.** There aren't a lot of guard rails to prevent you from making a mistake. User discretion is advised.

Examples of when you might want to do this:
* (Most common) Cleaning up when CI ends up with a broken `dev-gitlab-runner` cluster, e.g. the CI server reboots and orphans a Terraform lock.
* Collaborating with another developer in their dev cluster.
* Running multiple personal dev clusters (e.g. `dev-mrtyler-experiment1`).

1. Prepend `USER=gitlab-runner TF_VAR_environment=dev-gitlab-runner` to all `rake` commands.
   * Or, to add an additional dev cluster: `USER=mrtyler-experiment1 TF_VAR_environment=dev-mrtyler-experiment1`
   * `TF_VAR_environment` must contain `USER` as above. Otherwise, behavior is undefined.

## Continuous Integration / Continuous Delivery

See [CI-CD.md](CI-CD.md)

## Running manually in non-dev environments (stg, prd)

See [CI-CD.md#running-in-non-dev-environments](CI-CD.md#running-manually-in-non-dev-environments-stg-prd)

## History

This repo is the union of two older repos: [gpii-terraform-modules](https://github.com/mrtyler/gpii-terraform-modules) (formerly called `gpii-terraform`) and [gpii-terraform-live](https://github.com/mrtyler/gpii-terraform-live). I (@mrtyler) did not retain history when merging these two repos. Please refer to the above repos for archaeological expeditions.
