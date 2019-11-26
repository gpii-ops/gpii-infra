# ssl-cert-check

This chart allows to validate SSL certificates and export metrics in Prometheus format or submit them to Stackdriver.
Check out more at [GPII GitHub account](https://github.com/gpii-ops/ssl-cert-check).

## TL;DR;

```console
$ helm install path_to_chart/ssl-cert-check
```

## Introduction

This chart bootstraps a deployment of ssl-cert-check on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/ssl-cert-check
```

The command deploys ssl-cert-check on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

Please refer to the default values file for the configurable parameters of the chart.
