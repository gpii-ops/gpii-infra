# GPII Preferences

Here goes the service description.

## TL;DR;

```console
$ helm install path_to_chart/gpii-preferences
```

## Introduction

This chart bootstraps an GPII Preferences deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites
  - Kubernetes 1.8+ with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/gpii-preferences
```

The command deploys nginx-ingress on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

Here goes configuration details.
