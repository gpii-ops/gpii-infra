# Principles

This document describes various high-level prinicples, goals, and rules of thumb for gpii-infra.

## Design principles

* Favor pushing implementation "down the stack". The more we act like a "regular" Exekube project, the more we benefit from upstream improvements. Hence, favor Terraform code over in-line shell scripts over Ruby/Rake wrapper code.
   * Here is a [notable exception](https://github.com/gpii-ops/gpii-infra/pull/93/commits/5d307a373bd42505f066bb24f6686f107aed2728), where moving a calculation up to Ruby/Rake resulted in much simpler Terraform code.

## Operational principles

* Avoid deploying changes near the end of your work day.
* Avoid deploying on Friday or prior to a holiday.
* Create JIRA tickets for issues (mainly CI/CD) we encounter and fix - to track the
  work done and to have data for future reference.

### Kubernetes resource requests and limits

* Use [resource requests and limits](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/) for components that run in Kubernetes.
   * Among their many benefits, Stackdriver needs resource requests and limits to generate meaningful Kubernetes dashboards.
* Memory: use the same value for Request and Limit. This makes scheduling in the cluster more predictable.
* CPU: favor using the same value for Request and Limit as this makes scheduling in the cluster more predictable.
   * However, to ease running resource-intensive components (CouchDB, Flowmanager, Preferences) in clusters with fewer resources (dev environments), you may set a component's CPU Request to a smaller value of the component's CPU Limit (e.g. `Request = 0.5 * Limit`).
* To determine initial values for a component's Requests and Limits:
   * Observe the component at idle and under some load, e.g. by running Locust tests against the component or environment.
   * Add a buffer for safety, e.g. `1.5 * observed value`.
* Favor specifying default Requests and Limits as far "down the stack" as possible, i.e. favor Chart defaults over Terraform module defaults over environment-specific settings.

### Docker images

We should be well-aware of Docker images we use in our infrastructrue, as deploying an untrusted, potentially malicious, image poses a significant security threat.

As a rule of thumb: official Docker curated images (https://docs.docker.com/docker-hub/official_images/) or images directly published by trusted OSS projects are acceptable, otherwise we should build the images ourselves.

#### Fully-specified version vs "floating" patch version

* In general, and especially for critical components (e.g. couchdb), prefer to use a fully specified version (e.g. 2.3.0) for maximum predictability.
   * We have observed that even a so-called "fully-specified" version (e.g. couchdb:2.3.0) can change (Docker tags are mutable).
* For stable utility components (e.g. alpine), prefer using a "floating" patch version (e.g. 3.9, not 3.9.4). This allows us to quickly take advantage of security updates with little risk (it is unlikely that alpine:3.9.5 breaks something that worked in alpine:3.9.4).
