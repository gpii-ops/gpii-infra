# GPII Flowmanager

Flowmanager service is a part of Global Public Inclusive Infrastructure.
Check out more at [GPII GitHub account](https://github.com/gpii).

## TL;DR;

```console
$ helm install path_to_chart/gpii-flowmanager
```

## Introduction

This chart bootstraps a GPII Flowmanager deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled
  - [cert-manager](https://github.com/kubernetes/charts/tree/master/stable/cert-manager)

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/gpii-flowmanager
```

The command deploys gpii-flowmanager on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the gpii-flowmanager chart and their default values.

| Parameter                      | Description                                                                                  | Default                                                                   |
|--------------------------------|----------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| `acme.clouddnsProject`         | Required GCP project id to use for CLoudDNS                                                  | -                                                                         |
| `acme.email`                   | Optional email to use for registration with certificate issuer                               | `dev-null@raisingthefloor.org`                                                |
| `acme.server`                  | Optional ACME server for certificate issuer                                                  | `https://acme-staging-v02.api.letsencrypt.org/directory`                  |
| `datasourceHostname`           | Data source hostname for preferences service                                                 | `http://admin:password@couchdb-svc-couchdb.gpii.svc.cluster.local`        |
| `datasourceListenPort`         | data source port for flowmanager service                                                     | `5984`                                                                    |
| `dnsNames`                     | List of DNS host names                                                                       | `flowmanager.test.local`                                                  |
| `enableStackdriverTrace`       | Enable [GCP Stackdriver Trace](https://cloud.google.com/trace/)                              | `false`                                                                   |
| `flowmanagerListenPort`        | Port for flowmanager service to listen on                                                    | `8081`                                                                    |
| `image.checksum`               | Container image checksum                                                                     | `sha256:8547f22ae8e86d7b4b09e10d9ec87b1605b47dc37904171c84555a55462f161e` |
| `image.pullPolicy`             | Container image pullPolicy                                                                   | `IfNotPresent`                                                            |
| `image.repository`             | Container image repository                                                                   | `gpii/universal`                                                          |
| `nodeEnv`                      | Flowmanager NPM environment                                                                  | `gpii.config.cloudBased.flowManager.production`                           |
| `preferencesUrl`               | Preferences service url                                                                      | `http://preferences.gpii.svc.cluster.local`                               |
| `replicaCount`                 | Desired number of controller pods                                                            | `1`                                                                       |
| `resources`                    | Optional resource requests and limits for deployment                                         | `{}`                                                                      |
| `rollingUpdate.maxSurge`       | Max number of pods that can be created over the desired number during rolling update         | `25%`                                                                     |
| `rollingUpdate.maxUnavailable` | Max number of pods that can become unavailable during rolling update                         | `0`                                                                       |
| `svcListenPort`                | ClusterIP service port                                                                       | `80`                                                                      |
