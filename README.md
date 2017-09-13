# gpii-terraform

Following the pattern laid out in "[How to create reusable infrastructure with Terraform modules](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d)" and "[Terragrunt: Remote Terraform configurations](https://github.com/gruntwork-io/terragrunt#keep-your-remote-state-configuration-dry)", this repo describes both the state of deployed infrastructure ("houses") and the modules ("blueprints") that comprise the [GPII](http://gpii.net/).

## Getting Started

### Install packages

1. Install [terraform](https://releases.hashicorp.com/terraform/) **< 0.10** (0.10 has significant architectural changes so I'm waiting on this (non backward-compatible) upgrade; also, kitchen-terraform doesn't support 0.10 yet).
1. Install [terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt) **< 0.13** (0.13.0 doesn't work with terraform < 0.10 yet).
1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
1. Install [kops](https://github.com/kubernetes/kops#installing).
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
1. `cd` into the `gpii-terraform/dev/` directory.
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
   * Password is the output of `KOPS_STATE_STORE=s3://gpii-kubernetes-state kops get secrets kube --type secret -oplaintext --name <your cluster name>.gpii.net`.
1. Click "Workloads" for a good overview of what's happening in the cluster.

#### On the local machine

1. `KOPS_STATE_STORE=s3://gpii-kubernetes-state kops validate cluster`
   * Add `--name k8s-dev-mrtyler.gpii.net` if you have multiple clusters configured.
1. `kubectl get nodes --show-labels`
   * Add `--context k8s-dev-mrtyler.gpii.net` if you have multiple clusters configured.

#### On the remote machine

1. Configure ssh, as described in [Configure SSH](#configure-ssh).
1. `ssh admin@api.<your cluster name>` e.g. `ssh -i ~/.ssh/id_rsa.gpii-ci -o StrictHostKeyChecking=no admin@api.k8s-stg.gpii.net`
1. `sudo docker ps` to see that Kubernetes containers are running.
1. `/var/log/kube-apiserver.log` is a good place to look if things aren't working.
1. This [overview of how a Kubernetes cluster comes up when using kops](https://github.com/kubernetes/kops/blob/master/docs/boot-sequence.md) is helpful for low-level cluster debugging, e.g. "Why isn't my cluster coming up?!"

### Cleaning up

1. `cd` into the `gpii-terraform/dev/` directory.
1. `rake destroy`
1. `rake clobber`

## Troubleshooting

* Currently, this system builds everything in `us-east-2`. When inspecting cloud resources manually (e.g. via the AWS web dashboard), make sure this region is selected.
* This system uses a lot of rapidly-evolving software. If a tool reports strange errors that look like incompatibilities, try downgrading to an earlier version. [ansible-gpii-ci-worker](https://github.com/idi-ops/ansible-gpii-ci-worker/) should always contain a working combination of versions -- see [defaults/main.yml](https://github.com/idi-ops/ansible-gpii-ci-worker/blob/master/defaults/main.yml)
* Terraform uses [DynamoDB](https://aws.amazon.com/dynamodb/) for locking. An easy way to orphan a lock is to Ctrl-C out of Terraform in the middle of an operation. To delete the lock:
   * From the component where you lost the lock: `terragrunt force-unlock anything`
   * Terraform will tell you that `anything` doesn't match the lock ID and spit out a bunch of info including the correct lock ID.
   * Copy this ID and: `terragrunt force-unlock <correct-lock-id>`
   * You can also use the AWS web dashboard. Go to `DynamoDB -> Tables -> gpii-terraform-lock-table -> Items`. Select the lock(s) for your environment `-> Actions -> Delete`.
* The system -- terraform and kops, e.g. -- stores various kinds of state in S3. All environments share a single Bucket, but have separate Keys (directories, basically). If you are manipulating this state directly (experts only! but sometimes needed, e.g. to recover from upgrading to a non-backward compatible version of Terraform), take care to only make changes to the Keys related to your environment. Modifying the Bucket will affect other developers' environments as well as shared environments like `prd`!

### My cluster is messed up and I just want to get rid of it so I can start over

1. `rake destroy` - the cleanest way to terminate a cluster. However, it may fail if the cluster never converged.
1. `rake _destroy` - destroys cloud resources but does not undeploy GPII components. This can cause `_destroy` to get stuck: Rake and Terraform don't know about resources created by Kubernetes, such as load balancers. These Kubernetes-managed resources will block Terraform from deleting, e.g. the network in which the load balancer resides.
1. The AWS dashboard - I'm sorry that you're here, but the last step is manually deleting orphaned resources.
   * One helpful trick is to make a Resource Group (top bar `->` Resource Groups `->` Create a Resource Group) and find resources Tagged with `KubernetesCluster: k8s-dev-mrtyler.gpii.net`. [Here is one I made for my dev environment](https://resources.console.aws.amazon.com/r/group#sharedgroup=%7B%22name%22%3A%22k8s-dev-tyler%22%2C%22regions%22%3A%22all%22%2C%22resourceTypes%22%3A%22all%22%2C%22tagFilters%22%3A%5B%7B%22key%22%3A%22KubernetesCluster%22%2C%22values%22%3A%5B%22k8s-dev-tyler.gpii.net%22%5D%7D%5D%7D).
   * Not all cloud resources care Taggable so you may need to explore a little, but the Resource Group report should give you an idea of what kinds of resources are getting stuck.
   * Eventually, I plan to add a `rake exterminate` to automate the destruction of wayward resources.
1. The AWS dashboard, part 2 - various tools in the system store state in S3 and DynamoDB. If you encounter weird mismatch errors, you may need to perform more manual cleanup.
   * Check S3 Bucket `gpii-terraform-state` for Keys named after your environment (`k8s-dev-mrtyler.gpii.net`) and delete only those keys. Remember to check non-environment subdirectories like `prereqs`.
   * Check S3 Bucket `gpii-kubernetes-state` for Keys named after your environment (`k8s-dev-mrtyler.gpii.net`) and delete only those keys.
   * Check DynamoDB for orphaned locks. See section in [Troubleshooting](#troubleshooting).
1. Other stuff - a few more things to clean if you're still having problems.
   * Check for orphaned IAM Roles using the AWS dashboard and delete them.
   * Delete `$TMPDIR/rake-tmp` (`rake clobber` should take care of this but just in case).
   * Delete `~/.terraform.d` and any directories in your `gpii-terraform` sandbox named `.bundle`, `.kitchen`, or `.terraform`.

#### After everything is cleaned up

1. Run `rake _destroy` again afterwards to make sure Terraform agrees that all the old resources are gone and to clean up DNS entries.
1. `rake clobber` - cleans up generated files.

## Continuous Integration / Continuous Delivery

See [CI-CD.md](CI-CD.md)

## Running manually in non-dev environments (stg, prd)

See [CI-CD.md#running-in-non-dev-environments](CI-CD.md#running-manually-in-non-dev-environments-stg-prd)

## History

This repo is the union of two older repos: [gpii-terraform-modules](https://github.com/mrtyler/gpii-terraform-modules) (formerly called `gpii-terraform`) and [gpii-terraform-live](https://github.com/mrtyler/gpii-terraform-live). I (@mrtyler) did not retain history when merging these two repos. Please refer to the above repos for archaeological expeditions.
