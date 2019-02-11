[![CircleCI](https://circleci.com/gh/gpii-ops/gpii-infra.svg?style=svg)](https://circleci.com/gh/gpii-ops/gpii-infra)
# gpii-infra

This repository manages infrastructure for the [GPII](https://gpii.net/).

It has [GitHub Checks integration with CircleCI](https://circleci.com/docs/2.0/enable-checks/).

A [CircleCI pipeline](https://circleci.com/gh/gpii-ops/gpii-infra) will run for every PR opened against this repository.

Project structure:

* [Google Cloud Platform (GCP)](gcp/) *(stable)*
* [Common plumbing](common/) *(mostly for admins)*
* [Amazon Web Services (AWS)](aws/) *(DEPRECATED)*

Additional documents are available at the root of this repository:

* [One-time Setup](./ONE-TIME-SETUP.md) if this is your organization's first time using gpii-infra
* [Continuous Integration/Delivery Process](./CI-CD.md)
* [Testing the GPII frontend against the backend](./TESTING.md)
* [User Training Notes](./USER-TRAINING.md)
