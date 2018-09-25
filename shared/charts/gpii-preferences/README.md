# GPII Preferences

Preferences service is a part of Global Public Inclusive Infrastructure.
Check out more at [GPII GitHub account](https://github.com/gpii).

## TL;DR;

```console
$ helm install path_to_chart/gpii-preferences
```

## Introduction

This chart bootstraps a GPII Preferences deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled
  - [nginx-ingress](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress)
  - [cert-manager](https://github.com/kubernetes/charts/tree/master/stable/cert-manager)

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/gpii-preferences
```

The command deploys gpii-preferences on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

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
`replicaCount` | desired number of controller pods | `1`
`svc_listen_port` | ClusterIP service port | `80`
`preferences_listen_port` | port for preferences service to listen on | `8081`
`datasource_listen_port` | data source port for preferences service | `5984`
`datasource_hostname` | data source hostname for preferences service | `http://admin:password@couchdb-svc-couchdb.gpii.svc.cluster.local`
`node_env` | preferences node env | `gpii.config.preferencesServer.standalone.production`
`issuerRef.name` | name of the cert-manager issuer | `letsencrypt-production`
`issuerRef.kind` | kind of the cert-manager issuer | `Issuer`
`dnsNames` | list of host names for nginx-ingress controller | `preferences.test.local`
`secretKeyRef.name` | name of the secret with CouchDB connection details | `couchdb-secrets`
`secretKeyRef.key` | key of the secret with CouchDB connection details | `datasource_hostname`
`image.repository` | container image repository | `gpii/universal`
`image.checksum` | container image checksum | `sha256:f279c6ab7fa1c19e5f358a6a3d87a970eaf8d615c8b6181851fa086b6229b3a1`
`image.pullPolicy` | container image pullPolicy | `IfNotPresent`
