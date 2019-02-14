[![CircleCI](https://circleci.com/gh/gpii-ops/gpii-infra.svg?style=svg)](https://circleci.com/gh/gpii-ops/gpii-infra)
# gpii-infra

This repository manages infrastructure for the [GPII](https://gpii.net/).

It has GitHub Checks integration [with CircleCI](https://circleci.com/docs/2.0/enable-checks/).

[CircleCI pipeline](https://circleci.com/gh/gpii-ops/gpii-infra) will run for every PR opened into this repository.

Project structure:

* [Amazon Web Services (AWS)](aws/) *(stable but soon to be deprecated)*
* [Google Cloud Platform (GCP)](gcp/) *(beta but soon to be stable)*
* [Common plumbing](common/) *(mostly for admins)*

Additional documents are available at the root of this repository:

* [Continuous Integration/Delivery Process](./CI-CD.md)
* [Testing the GPII frontend against the backend](./TESTING.md)
* [User Training Notes](./USER-TRAINING.md)
