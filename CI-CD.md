# Continuous Integration / Continuous Delivery

This repo is designed to fit into a CI/CD scheme: new commits are automatically tested and promoted through a pipeline.

[High-level architecture diagram](https://docs.google.com/presentation/d/1vkVi1iCDSqdfC9YPmpd-xyUJORFtXE72soLtFLHEEcg/view)

## Configure AWS

   * One design goal of this infrastructure is to use the same code to spin up clusters for development and production. This model bumps up against some of Amazon's (fairly conservative) default limits for various resource types. Usually this kind of failure is obvious from the error message returned by AWS ("Your quota allows for 0 more running instance(s).").
      * The general procedure for increasing a limit is: web search "aws <name of thing> limit", find Amazon documentation about the limit, click link in documentation to service request form for increasing said limit, wait for response from Amazon support.
      * Limits we've hit and increased: number of VPCs, number of ASGs, number of EC2 Instances (t2.micro through t2.large).

## Configure Github

   * Create a role account `gpii-bot` for use by `gitlab-runner`. Add it to the `gpii-ops` Organization. Add it to the `gpii-terraform` repo as a Collaborator with Write access.
      * You'll need to accept the invitation using `gpii-bot`'s Github account.
   * Create an ssh key. Associate the public key with the `gpii-bot` Github account. Save the private key as `~gitlab-runner/.ssh/id_rsa.gpii-ci`.

## Configure Gitlab

   * Import the `gpii-terraform` repo from Github into the `gpii-ops` Gitlab organization.
      * In that repo, disable all Shared Runners.
      * Note the Registration Token for this project. You'll need to give it to Ansible later.
   * Create a role account `gpii-bot` for use by `gitlab-runner`. Add it to the `gpii-ops` Organization with `Master` permissions.
   * Associate the public key above (from Github) with the `gpii-bot` Gitlab account.

## Configure Docker Hub

   * Create a [Docker Hub](https://hub.docker.com) account `gpiibot` for use by `gitlab-runner`. Add it to the `Owners` group of the `gpii` Organization.

## Configure a build node

   * Add the Gitlab Project and Registration Token from [Configure Gitlab](CI-CD.md#configure-gitlab) to `vault.yml`.
   * Apply the ansible role [ansible-gpii-ci-worker](https://github.com/idi-ops/ansible-gpii-ci-worker) to the build node.
      * The [internal ansible repo](https://github.com/inclusive-design/ops) has a playbook to do this: `config_host_gpii_ci_worker.yml`.

### Set up credentials

   * [Set up .ssh with gpii-key.pem](README.md#configure-ssh).
      * Make sure the private key associated with the gitlab-runner Github account is available at `~gitlab-runner/.ssh/id_rsa.gpii-ci`.
   * [Configure AWS creds](README.md#install-packages) for `gitlab-runner`.

## gpii-version-updater

   * There is a standalone system for managing the versions of GPII components running on this infrastructure, via [version.yml](https://github.com/gpii-ops/gpii-terraform/blob/master/modules/deploy/version.yml). See the [gpii-version-updater repo](https://github.com/gpii-ops/gpii-version-updater).

## Running manually in non-dev environments (stg, prd)

`dev-*` environments are built with code from `master`, but other environments (e.g. `stg`, `prd`) are controlled with version tags. The CD process handles versioning automatically, but in case manual intervention is required:
   * Make sure any local changes are committed or stashed (`git status`).
   * `git checkout $(git tag | grep ^deploy-stg- | sort | tail -1)`
   * `cd stg`
   * `rake ...`
   * `git checkout master`

## Setting the version for an environment manually

The best and simplest way is to make `master` correct (e.g. by reverting a commit that didn't work as expected) and let the CD system work it out. However, if exceptional circumstances occur:
   * Note that git tags are [effectively immutable](https://git-scm.com/docs/git-tag#_on_re_tagging), so forget about re-pointing the last deploy tag.
   * Make a new tag: `git tag deploy-stg-$(date -u '+%Y%m%d%H%M%S') <commit env should use>`
   * `git push --tags origin`
   * `git checkout` the new tag and `rake`, as above.
