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
  - [nginx-ingress](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress)
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

Parameter | Description | Default
--- | --- | ---
`replicaCount` | desired number of controller pods | `1`
`svc_listen_port` | ClusterIP service port | `80`
`flowmanager_listen_port` | port for flowmanager service to listen on | `8081`
`datasource_listen_port` | data source port for flowmanager service | `5984`
`datasource_hostname` | data source hostname for preferences service | `http://admin:password@couchdb-svc-couchdb.gpii.svc.cluster.local`
`node_env` | flowmanager node env | `gpii.config.cloudBased.flowManager.production`
`preferences_url` | preferences service url | `http://preferences.gpii.svc.cluster.local`
`enableStackdriverTrace` | enable [GCP Stackdriver Trace](https://cloud.google.com/trace/) | `false`
`issuerRef.name` | name of the cert-manager issuer | `letsencrypt-production`
`issuerRef.kind` | kind of the cert-manager issuer | `Issuer`
`dnsNames` | list of host names for nginx-ingress controller | `flowmanager.test.local`
`image.repository` | container image repository | `gpii/universal`
`image.checksum` | container image checksum | `sha256:8547f22ae8e86d7b4b09e10d9ec87b1605b47dc37904171c84555a55462f161e`
`image.pullPolicy` | container image pullPolicy | `IfNotPresent`
`rollingUpdate.maxSurge` | maximum number of pods that can be created over the desired number during rolling update | `25%`
`rollingUpdate.maxUnavailable` | maximum number of pods that can become unavailable during rolling update | `0`
`resources` | optional resource requests and limits for deployment | `{}`
