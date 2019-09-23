# GPII Production Configuration Tests

The production configuration tests job is a part of Global Public Inclusive Infrastructure.
Check out more at [GPII GitHub account](https://github.com/gpii).

## TL;DR;

```console
$ helm install path_to_chart/gpii-productiontests
```

## Introduction

This chart bootstraps a deployment of GPII production tests on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/gpii-productiontests
```

The command deploys gpii-productiontests on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the gpii-productiontests chart and their default values.

Parameter | Description | Default
--- | --- | ---
`couchdb.labels` | CouchDB pod labels for `NetworkPolicy` | `{ app: "couchdb" }`
`couchdb.port` | CouchDB port for `NetworkPolicy` (can either be a numerical or named port on a pod) | `http-couchdb`
`couchdb.url` | CouchDB url for productionTests | `http://admin:password@couchdb-svc-couchdb.gpii.svc.cluster.local:5984/gpii`
`flowmanager.url` | Cloud based flowmanager url whose end points are tested | `http://flowmanager.gpii.svc.cluster.local:80`
`flowmanager.labels` | Cloud based flow manager labels for `NetworkPolicy` | `{ app: "flowmanager" }`
`flowmaanger.svcListenport` | Cloud based flowmanager port for `NetworkPolicy` (can either be a numerical or named port on a pod) | `http`
`flowmanager.flowmanagerListenPort` | Local flowmanager port | `8080`
`image.repository` | container image repository | `gpii/universal`
`image.checksum` | container image checksum | `sha256:8ac150765ea0e582ae6d4372b6029396df7409bdb55ee261bc58d5016a7c5c58`
`image.pullPolicy` | container image pullPolicy | `IfNotPresent`
