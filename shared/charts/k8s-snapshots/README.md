# K8s-snapshots

K8s-snapshots is an AWS and GCP volume backup utility.  Check out more at
[project homepage](https://github.com/miracle2k/k8s-snapshots).

## TL;DR;

```console
$ helm install path_to_chart/k8s-snapshots
```

## Introduction

This chart bootstraps k8s-snapshots deployment on a
[Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh)
package manager.

## Prerequisites

  - Kubernetes 1.8+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/k8s-snapshots
```

The command deploys k8s-snapshots on the Kubernetes cluster in the default
configuration. The [configuration](#configuration) section lists the parameters
that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.

## Configuration

The following table lists the configurable parameters of the gpii-dataloader
chart and their default values.

| Parameter          | Description                                                       | Default                    |
|--------------------|-------------------------------------------------------------------|----------------------------|
| `image.repository` | container image repository                                        | `elsdoerfer/k8s-snapshots` |
| `image.tag`        | container image tag                                               | `v2.0`                     |
| `image.pullPolicy` | container image pullPolicy                                        | `IfNotPresent`             |
| `useClaimName`     | If `true`, set USE_CLAIM_NAME environment variable for deployment | `true`                     |
| `runOnMasters`     | If `true`, apply toleration to run on master nodes to deployment  | `false`                    |
| `rbac.create`      | If `true`, create and use RBAC resources                          | `true`                     |
| `replicaCount`     | desired number of deployment pods                                 | `1`                        |
| `serviceAccount`   | GCP Service Account to be assigned to pod                         | `default`                  |
| `scopes`           | GCP Scopes to be assigned to pod                                  | `cloud-platform`           |
