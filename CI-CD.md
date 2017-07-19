# Continuous Integration / Continuous Delivery

This repo is designed to fit into a CI/CD scheme: new commits are automatically tested and promoted through a pipeline.

[High-level architecture diagram](https://docs.google.com/presentation/d/1sly5V5ayg0q5bnzkutIHslmDdjHeZZIIXbEBzbjEqTs/view)

## Configure Github

   * Create a role account `gpii-bot` for use by `gitlab-runner`. Add it to the `gpii-ops` Organization. Add it to the `gpii-terraform` and `gpii-terraform-live` repos as a Collaborator with Write access.
   * Create an ssh key. Associate the public key with the `gpii-bot` Github account. Save the private key as `~gitlab-runner/.ssh/id_rsa.gpii-ci`.

## Configure Gitlab

   * Import `gpii-terraform` and `gpii-terraform-live` repos from Github into the `gpii-ops` Gitlab organization.
      * In those repos, disable all Shared Runners. Ansible will enable Specific Runners later.
   * Create a role account `gpii-bot` for use by `gitlab-runner`. Add it to the `gpii-ops` Organization with `Master` permissions.
   * Associate the public key above (from Github) with the `gpii-bot` Gitlab account.

## Configure a build node
   * Apply the ansible role [ansible-gpii-ci-worker](https://github.com/idi-ops/ansible-gpii-ci-worker) to the build node.
      * The [internal ansible repo](https://github.com/inclusive-design/ops) has a playbook to do this: `config_host_gpii_ci_worker.yml`.

### Set up credentials
   * [Set up .ssh with gpii-key.pem](https://github.com/gpii-ops/gpii-terraform-live#configure-ssh).
      * Make sure the private key associated with the gitlab-runner Github account is available at `~gitlab-runner/.ssh/id_rsa.gpii-ci`.
   * [Configure AWS creds](https://github.com/gpii-ops/gpii-terraform-live#configure-your-machine) for `gitlab-runner`.

## Running manually in non-dev environments (stg, prd)

`dev-*` environments are built with code from `master`, but other environments (e.g. `stg`, `prd`) are controlled with version tags. The CD process handles versioning automatically, but in case manual intervention is required:
   * Make sure any local changes are committed or stashed (`git status`).
   * `git checkout $(git tag | grep ^deploy-stg- | sort | tail -1)`
   * `cd stg`
   * `terragrunt ...`
   * `git checkout master`

## Setting the version for an environment manually

The best and simplest way is to make `master` correct (e.g. by reverting a commit that didn't work as expected) and let the CD system work it out. However, if exceptional circumstances occur:
   * Note that git tags are [effectively immutable](https://git-scm.com/docs/git-tag#_on_re_tagging), so forget about re-pointing the last deploy tag.
   * Make a new tag: `git tag deploy-stg-$(date -u '+%Y%m%d%H%M%S') <commit env should use>`
   * `git push --tags origin`
