# CouchDB Prometheus Exporter

[couchdb-prometheus-exporter](https://github.com/gesellix/couchdb-prometheus-exporter) is a [CouchDB](http://couchdb.apache.org/) metrics exporter for [Prometheus](http://prometheus.io/)

The CouchDB metrics exporter requests the CouchDB stats from the `/_stats` and `/_active_tasks` endpoints and exposes them for Prometheus consumption. You can optionally monitor detailed database stats like disk and data size to monitor the storage overhead. The exporter can be configured via program parameters, environment variables, and config file.


## TL;DR;

```console
$ helm install path_to_chart/couchdb-prometheus-exporter
```

## Introduction

This chart bootstraps a CouchDB Prometheus Exporter deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/couchdb-prometheus-exporter
```

The command deploys couchdb-prometheus-exporter on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the gpii-preferences chart and their default values.

Parameter | Description | Default
--- | --- | ---
`replicaCount` | desired number of pods | `1`
`exporterListenPort` | port for exporter service to listen on | `9984`
`couchdb.labels` | CouchDB pod labels for `NetworkPolicy` | `{ app: "couchdb" }`
`couchdb.port` | CouchDB port for `NetworkPolicy` (can either be a numerical or named port on a pod) | `http-couchdb`
`couchdb.uri` | URI for couchdb | `http://couchdb-svc-couchdb.default.svc.cluster.local:5984`
`couchdb.username` | username for couchdb uri | `admin`
`couchdb.password` | password for couchdb uri | `password`
`couchdb.databases` | list of specific databases to monitor | `_all_dbs`
`image.repository` | container image repository | `gesellix/couchdb-prometheus-exporter`
`image.tag` | container image checksum | `22`
`image.pullPolicy` | container image pullPolicy | `IfNotPresent`
`image.prometheusToSdExporter.repository` | prometheus-to-sd container image repository | `gcr.io/google-containers/prometheus-to-sd`
`image.prometheusToSdExporter.tag` | prometheus-to-sd container image tag | `v0.5.1`
`image.pullPolicy` | prometheus-to-sd container image pullPolicy | `IfNotPresent`
`resources` | optional resource requests and limits for deployment | `requests:`<br/>&nbsp;&nbsp;`cpu: 10m`<br/>&nbsp;&nbsp;`memory: 60Mi`<br/>`limits:`<br/>&nbsp;&nbsp;`cpu: 10m`<br/>&nbsp;&nbsp;`memory: 60Mi`
