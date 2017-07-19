# gpii-terraform-live

Following the pattern laid out in "[How to create reusable infrastructure with Terraform modules](https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules)" and "[Terragrunt: Remote Terraform configurations](https://github.com/gruntwork-io/terragrunt#remote-terraform-configuration)", this repo describes the state of deployed infrastructure ("houses"). The modules ("blueprints") live [here](https://github.com/gpii-ops/gpii-terraform).

## Getting Started

### Configure your machine

1. Install [terraform](https://releases.hashicorp.com/terraform/).
1. Install [terragrunt](https://github.com/gruntwork-io/terragrunt#install).
1. Get an AWS access key and secret key, as described [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html).
1. Configure AWS credentials:
   * _Recommended:_ Install the [AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) and run `aws configure` per [the docs](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration). Fill in the access key and secret key you downloaded from Amazon. Leave the other prompts empty.
   * _Or:_ Manually configure `~/.aws` to look like the examples [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-multiple-profiles).
1. Verify your AWS credential configuration: `aws sts get-caller-identity`

### Provision an environment

1. Clone this repo.
1. Clone [gpii-terraform, the repo containing the modules](https://github.com/gpii-ops/gpii-terraform), into a directory next to the clone of this repo (i.e. `gpii-terraform/` and `gpii-terraform-live/` should be in the same directory).
1. `cd` into the `gpii-terraform-live/dev/` directory.
1. `terragrunt apply-all`
   * The first time this is run in a given AWS account, terragrunt will prompt you to confirm the creation of a DynamoDB entry (for locking) and an S3 bucket (for remote state). You must also "opt-in" to use of the Amazon Marketplace CentOS 7 image (the API returns an error with a link to a page where you click buttons).
   * This will create an independent dev environment called `dev-$USER` (or `dev-unknown-user` if you don't have `$USER` set in your shell environment -- but you should set it so you don't conflict with someone else who doesn't have `$USER` set).

### Configure SSH

1. Get a copy of `gpii-key.pem` from `~deploy/.ssh` on `i40`. Put it at `~/.ssh/gpii-key.pem`
   * The destination path is hardcoded into `.kitchen.yml` and the terraform code responsible for provisioning instances.
   * The configuration process could create user accounts (there is already ansible code in the `ops` repo to do this) but for now we'll use a shared key.
1. For ad-hoc debugging and ansible: `ssh-add ~/.ssh/gpii-key.pem`

### Configure an environment with Ansible (deprecated)

1. Configure ssh, as described in [Configure SSH](#configure-ssh).
1. Install [terraform-inventory](https://github.com/adammck/terraform-inventory) into `/usr/local/bin` (or somewhere else and update the path in the command below).
1. Clone [the internal ansible repo](https://github.com/inclusive-design/ops) and `cd` into the `ansible/` directory.
1. `TF_STATE=$(find "$TMPDIR/terragrunt-download" -name terraform.tfstate -path '*/worker/*' | xargs ls -tr | tail -1) ANSIBLE_REMOTE_PORT=22 ansible-playbook -i /usr/local/bin/terraform-inventory deploy_containers_gpii_stg.yml --user centos`

### Manual testing

1. Configure ssh, as described in [Configure SSH](#configure-ssh).
1. In your clone of this repo, `terragrunt output-all` and find `public_ip`. (You can also just look in your scrollback.)
1. `ssh centos@<public_ip>`
1. `sudo docker ps` to see that containers are running (deprecated)
1. `curl localhost:38082/preferences/carla` (deprecated)
   * If it returns some JSON, you have a working Preferences server.

### Automated testing

1. Install Ruby and [Bundler](http://bundler.io/) (for [kitchen](https://github.com/test-kitchen/test-kitchen) and [kitchen-terraform](https://github.com/newcontext-oss/kitchen-terraform)).
   * I like [rvm](https://rvm.io/) for ruby management.
   * If you're using a package manager, you may need to install "ruby-devel" as well.
1. Install [jq](https://stedolan.github.io/jq/).
1. Clone this repo, [gpii-terraform-live](https://github.com/gpii-ops/gpii-terraform-live), and `cd` into `dev/`.
1. `bundle install --path vendor/bundle`
1. Configure ssh, as described in [Configure SSH](#configure-ssh).
1. `bundle exec kitchen test`
   * This will **destroy**/create/test/**destroy** resources in the same `dev-$USER` environment that is managed with `terragrunt *-all`.
   * `kitchen test` runs a series of phases: `destroy, create, converge, verify, destroy,` and a few others. You can run these phases by hand (e.g. `kitchen converge && kitchen verify`) to avoid **destroying the whole environment** after a successful test run.
   * Add `-l debug` to see more log output.

### Cleaning up

1. From the directory where you ran `terragrunt apply-all`, run `terragrunt destroy-all`.

### Running manually in non-dev environments (stg, prd)

See [CI-CD.md#running-in-non-dev-environments](https://github.com/gpii-ops/gpii-terraform-live/blob/master/CI-CD.md#running-manually-in-non-dev-environments-stg-prd)

## Continuous Integration / Continuous Delivery

See [CI-CD.md](https://github.com/gpii-ops/gpii-terraform-live/blob/master/CI-CD.md)
