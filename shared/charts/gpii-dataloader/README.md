# GPII Dataloader

Dataloader job is a part of Global Public Inclusive Infrastructure.
Check out more at [GPII GitHub account](https://github.com/gpii).

## TL;DR;

```console
$ helm install path_to_chart/gpii-dataloader
```

## Introduction

This chart bootstraps a GPII Dataloader deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/gpii-dataloader
```

The command deploys gpii-dataloader on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

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
`couchdb.labels` | CouchDB pod labels for `NetworkPolicy` | `{ app: "couchdb" }`
`couchdb.port` | CouchDB port for `NetworkPolicy` (can either be a numerical or named port on a pod) | `http-couchdb`
`couchdb.url` | CouchDB url for dataloader | `http://admin:password@couchdb-svc-couchdb.gpii.svc.cluster.local:5984/gpii`
`image.repository` | container image repository | `gpii/universal`
`image.checksum` | container image checksum | `sha256:fa3bbf3a8255be83552da35b84a1a005d5cb3a44627510171a5a5eb11b2aea89`
`image.pullPolicy` | container image pullPolicy | `IfNotPresent`
