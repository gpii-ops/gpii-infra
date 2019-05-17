# backup-exporter

backup-exporter is an GCP volume backup utility.

## TL;DR;

```console
$ helm install path_to_chart/backup-exporter
```

## Introduction

This chart bootstraps backup-exporter deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/backup-exporter
```

The command deploys backup-exporter on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the gpii-dataloader chart and their default values.

Parameter | Description | Default
--- | --- | ---
`image.repository` | container image repository | `google/cloud-sdk`
`image.tag` | container image tag | `latest`
`image.pullPolicy` | container image pullPolicy | `IfNotPresent`
`serviceAccountName` | service account used to perform all the actions | ``
`destinationBucket` | destination bucket for storing the backups | ``
`schedule` | schedule configuration, crontab format | `0 0 * * *`
