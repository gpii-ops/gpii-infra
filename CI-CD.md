# Continuous Integration / Continuous Delivery

This repo is designed to fit into a CI/CD scheme: new commits are automatically tested and promoted through a pipeline.

* [GPII Build and Release Overview](https://docs.google.com/presentation/d/1l8qQEvFaml_qgc0fynHScVhWseu0loytcYaFP_m0tBs) - overview of how GPII is built, tested, and deployed to the public cloud
* [A more detailed view of CI/CD](https://docs.google.com/presentation/d/1vkVi1iCDSqdfC9YPmpd-xyUJORFtXE72soLtFLHEEcg/view) - this one has more about gpii-version-updater
* DEPRECATED [GPII Build and Release Overview (AWS Version)](https://docs.google.com/presentation/d/1yXGCHBDtb07Gw0do2ZcnUQ0R-g6z4w6uDlqxBnr8Yxo) - overview of the AWS-based infrastructure

## One-time setup steps

### Configure GCP

1. Log in to the CI Worker as `gitlab-runner` and clone this repo.
   * It would be better to do this as a non-shared account, but the way Ruby is installed on the CI worker makes this difficult.
1. `cd gpii-infra/ && rake -f rakefiles/ci_save_all.rake` and follow the authentication prompts.

### Configure Github

   * Create a role account `gpii-bot` for use by `gitlab-runner`. Add it to the `gpii-ops` Organization. Add it to the `gpii-infra` repo as a Collaborator with Write access.
      * You'll need to accept the invitation using `gpii-bot`'s Github account.
   * Create an ssh key. Associate the public key with the `gpii-bot` Github account. Save the private key as `~gitlab-runner/.ssh/id_rsa.gpii-ci`.

### Configure Gitlab

   * Import the `gpii-infra` repo from Github into the `gpii-ops` Gitlab organization.
      * In that repo, disable all Shared Runners.
      * Note the Registration Token for this project. You'll need to give it to Ansible later.
   * [Schedule](https://docs.gitlab.com/ce/user/project/pipelines/schedules.html) a Nightly build of the `gpii-infra` project. This ensures the system is exercised regularly, even when there are no changes to the code base.
   * Create a role account `gpii-bot` for use by `gitlab-runner`. Add it to the `gpii-ops` Organization with `Master` permissions.
   * Associate the public key above (from Github) with the `gpii-bot` Gitlab account.

#### Configure Gitlab Secret Variables

Until we have better credential management (i.e. Vault integration), we fall back to that oldest of techniques: injection via environment variables stored in a safe place -- [Gitlab Secret Variables](https://gitlab.com/gpii-ops/gpii-infra/settings/ci_cd).

Examples of things that get credentials this way include: CouchDB, Alertmanager. For an exhaustive list, see [`:setup_secrets`](https://github.com/gpii-ops/gpii-infra/blob/master/modules/deploy/Rakefile).

### Configure Docker Hub

   * Create a [Docker Hub](https://hub.docker.com) account `gpiibot` for use by `gitlab-runner`. Add it to the `Owners` group of the `gpii` Organization.

### Configure a build node

   * Add the Gitlab Project and Registration Token from [Configure Gitlab](CI-CD.md#configure-gitlab) to `vault.yml`.
   * Apply the ansible role [ansible-gpii-ci-worker](https://github.com/idi-ops/ansible-gpii-ci-worker) to the build node.
      * The [internal ansible repo](https://github.com/inclusive-design/ops-shared) has a playbook to do this: `config_host_gpii_ci_worker.yml`.

### Configure gpii-version-updater

   * There's a bit of back-and-forth here during initial deployment.
      * First, gpii-infra must create the Google Container Registry instance and associated IAMs.
      * Then, gpii-version-updater must run to sync images to the GCR instance.
      * Finally, gpii-infra can deploy environments using the images pushed to the GCR instance.
   * Create a Key for the gcr-uploader Service Account and download it.
   * Add the contents of the Key file to `vault.yml`.
   * Apply the ansible role [ansible-gpii-version-updater](https://github.com/idi-ops/ansible-gpii-version-updater) to the build node.
      * The [internal ansible repo](https://github.com/inclusive-design/ops) has a playbook to do this: `config_host_gpii_version_updater.yml`.
      * You'll need the ssh key you [configured with Github](#configure-github).

### Configure AWS (DEPRECATED)

   * One design goal of this infrastructure is to use the same code to spin up clusters for development and production. This model bumps up against some of Amazon's (fairly conservative) default limits for various resource types. Usually this kind of failure is obvious from the error message returned by AWS ("Your quota allows for 0 more running instance(s).").
      * The general procedure for increasing a limit is: web search "aws <name of thing> limit", find Amazon documentation about the limit, click link in documentation to service request form for increasing said limit, wait for response from Amazon support.
      * Limits we've hit and increased: number of VPCs, number of ASGs, number of EC2 Instances (t2.micro through t2.large).

### Set up credentials (DEPRECATED)

   * [Set up .ssh with gpii-key.pem](README.md#configure-ssh).
      * Make sure the private key associated with the gitlab-runner Github account is available at `~gitlab-runner/.ssh/id_rsa.gpii-ci`.
   * [Configure AWS creds](README.md#install-packages) for `gitlab-runner`.

## Running manually in non-dev environments (stg, prd)

**Note: this is an advanced workflow.** User discretion is advised.

**Note2: ESPECIALLY IF PRD IS INVOLVED!** Experts only! Work with a buddy!

`dev-*` environments are built with code from `master`, but other environments (e.g. `stg`, `prd`) are controlled with version tags. The CD process handles versioning automatically, but in case manual intervention is required:
   * Make sure any local changes are committed or stashed (`git status`).
   * `git checkout $(git tag | grep ^deploy-aws-stg- | sort | tail -1)`
   * `cd stg`
   * If you will `rake deploy` (or just `rake`, as `rake deploy` is the default operation) or otherwise make changes to anything that uses credentials, you will need to manually configure your local environment. See [Configure Gitlab Secret Variables](#configure-gitlab-secret-variables).
   * `rake ...`
   * `git checkout master`

## Setting the version for an environment manually

The best and simplest way is to make `master` correct (e.g. by reverting a commit that didn't work as expected) and let the CD system work it out. However, if exceptional circumstances occur:
   * Note that git tags are [effectively immutable](https://git-scm.com/docs/git-tag#_on_re_tagging), so forget about re-pointing the last deploy tag.
   * Make a new tag: `git tag deploy-gcp-stg-$(date -u '+%Y%m%d%H%M%S') <commit that should be running in env>`
   * `git push --tags origin`
   * `git checkout` the new tag and `rake`, as above.
