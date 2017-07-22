# gpii-terraform

Following the pattern laid out in "[How to create reusable infrastructure with Terraform modules](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d)" and "[Terragrunt: Remote Terraform configurations](https://github.com/gruntwork-io/terragrunt#keep-your-remote-state-configuration-dry)", this repo describes both the state of deployed infrastructure ("houses") and the modules ("blueprints") that comprise the [GPII](http://gpii.net/).

## Getting Started

### Install packages

1. Install [terraform](https://releases.hashicorp.com/terraform/).
1. Install [terragrunt](https://github.com/gruntwork-io/terragrunt#install-terragrunt).
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
   * This will create an independent dev environment called `dev-$USER`, run tests, and then **destroy the environment**.
   * Add `RAKE_NO_DESTROY=1` if you want the environment to stick around after tests run.

#### Warning about simultaneous runs

The build process (orchestrated by `rake`) tries to provide isolation for different environments. However, there is only one `modules/` directory in the source tree where dynamic code generation occurs. Hence, use caution running, say, `rake dev` and `rake stg` from the same working copy.

### Manual testing

#### On the local machine

1. `KOPS_STATE_STORE=s3://gpii-kubernetes-state kops validate cluster`
   * Add `--name k8s-dev-mrtyler.gpii.net` if you have multiple clusters configured.
1. `kubectl get nodes --show-labels`
   * Add `--context k8s-dev-mrtyler.gpii.net` if you have multiple clusters configured.

#### On the remote machine

1. Configure ssh, as described in [Configure SSH](#configure-ssh).
1. `ssh admin@api.<your cluster name>` e.g. `ssh admin@api.k8s-dev-mrtyler.gpii.net`
1. `sudo docker ps` to see that Kubernetes containers are running

### Cleaning up

1. `cd` into the `gpii-terraform/dev/` directory.
1. `rake destroy`

## Continuous Integration / Continuous Delivery

See [CI-CD.md](CI-CD.md)

## Running manually in non-dev environments (stg, prd)

See [CI-CD.md#running-in-non-dev-environments](CI-CD.md#running-manually-in-non-dev-environments-stg-prd)

## History

This repo is the union of two older repos: [gpii-terraform-modules](https://github.com/mrtyler/gpii-terraform-modules) (formerly called `gpii-terraform`) and [gpii-terraform-live](https://github.com/mrtyler/gpii-terraform-live). I (@mrtyler) did not retain history when merging these two repos. Please refer to the above repos for archaeological expeditions.
