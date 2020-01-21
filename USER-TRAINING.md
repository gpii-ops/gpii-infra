# User training

This document is for Ops team members setting up new developers to work in the GPII cloud.

## Before sitting down with the user

1. Email the user some homework. Here is a template:
> Hello _USER_,
>
> Before we meet on _DATE_ to set up your GPII Cloud development environment, please prepare a few things:
>
> 1. A UNIX command-line environment. Popular approaches include MacOS, or Linux running in a Vagrant VM. Let me know if you would like more information about this.
> 1. Please provide me the result of running 'echo $USER' in that command-line environment.
> 1. Install required packages in this command-line environment -- https://github.com/gpii-ops/gpii-infra/tree/master/gcp#install-packages
> 1. If you already have an @RtF Google account (i.e. an @RtF email), make sure you have Multi-Factor Authentication (MFA) enabled -- https://github.com/gpii-ops/gpii-infra/tree/master/gcp#enable-multi-factor-authentication-mfa-on-your-account
>
>Thanks!
2. Set up an account using the `$USER` value the user provided in response to your email -- see next section
3. [Create a GCP Project for the user](./common/README.md#adding-a-dev-project)

### GCP: Setting up the user's account

_Note: there are pre-requisite steps in [ONE-TIME-SETUP.md](ONE-TIME-SETUP.md)._

* If the user does not have an @RtF email address (e.g. an OCAD developer who works on GPII but is not part of RtF):
   * From the [G Suite Admin Users page](https://admin.google.com/u/1/ac/users), add a new User
   * Move to Organizational Unit "Cloud Development Only"
   * Add a forwarding rule to [Gmail's Recipient Address Map](https://support.google.com/a/answer/4524505?hl=en) from the user's new @RtF email (Gmail is disabled for these users) to the user's primary email (e.g. their OCAD email)

* For all users:
   * Add to Group "cloud-developers"

## Introduction

* Ask the user about their experience with infrastructure, command-line tools, cloud computing, etc.
   * Let their responses guide how much you delve into or gloss over fine details, how much background information might be helpful, etc.

## The Speech

* You are about to be granted administrative (aka "root") access to a number of resources on the public internet. This is a serious responsiblity!
* Measure twice, cut once.
* If you're ever in doubt about what a command will do, STOP! Then ask for help.
   1. First, ask other developers who have experience using gpii-infra
   1. Next, ask #ops in Slack, or #fluid-work or #fluid-tech in IRC
* Be ethical. Don't steal data. Don't run your startup on RtF's billing account.
* RtF pays for these resources so please destroy your environment when you're done using it, or won't use it for a while (e.g. before the weekend).

## Overview of the system

* Go over the [Build and Release Overview slide deck](https://docs.google.com/presentation/d/1l8qQEvFaml_qgc0fynHScVhWseu0loytcYaFP_m0tBs/edit#slide=id.g3150fb0231_0_0) with the user.
   * Remember that many product developers don't have a lot of experience with infrastructure tools and concepts. Introduction of high-level concepts like containers, container orchestration, and automated deployment as well as a general view of how the pieces fit together is the goal; the fine details are less important.

## GCP: Your first environment
* Direct user to follow the [Getting Started instructions in the gpii-infra GCP README](gcp/README.md#getting-started).
