[![CircleCI](https://circleci.com/gh/gpii-ops/gpii-infra.svg?style=svg)](https://circleci.com/gh/gpii-ops/gpii-infra)
# gpii-infra

This repository manages infrastructure for the [GPII](https://gpii.net/).

## Getting started

[Start here](gcp/README.md#getting-started) if you are a GPII developer who wants to create a personal GPII Cloud for development or testing.

## Subprojects

GPII infrastructure comes in a few "flavors".

* [Google Cloud Platform (GCP)](gcp/) *(stable, most users want this)*
* [Common plumbing](common/) *(mostly for admins)*

## Other documents

* [Contacting Ops](./CONTACTING-OPS.md) in case of questions or operational emergency
* [One-time Setup](./ONE-TIME-SETUP.md) if this is your organization's first time using gpii-infra
* [Continuous Integration/Delivery Process](./CI-CD.md)
* [Principles](./PRINCIPLES.md) of design, development, and operation
* [Testing the GPII frontend against the backend](./TESTING.md)
* [User Training Notes](./USER-TRAINING.md)

## Tools

This repo has [GitHub Checks integration with CircleCI](https://circleci.com/docs/2.0/enable-checks/).

A [CircleCI pipeline](https://circleci.com/gh/gpii-ops/gpii-infra) will run for every PR opened against this repository.

A [GitLab pipeline](https://gitlab.com/gpii-ops/gpii-infra/pipelines) handles CI/CD. See also [Continuous Integration/Delivery Process](./CI-CD.md).
