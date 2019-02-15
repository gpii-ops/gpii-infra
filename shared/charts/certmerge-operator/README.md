# certmerge-operator chart

Certmerge-operator is a Kubernetes Operator that can merge many TLS secrets
in one Opaque secret.

This is required for using Istio Gateway with more than one TLS certificate and
certificates issued and managed by cert-manager.

See https://github.com/prune998/certmerge-operator for usage details.

## Configuration

The following table lists the configurable parameters of the chart and their
default values.

| Parameter          | Description                | Default                   |
|--------------------|----------------------------|-------------------------- |
| `image.repository` | container image repository | `gpii/certmerge-operator` |
| `image.pullPolicy` | container image pullPolicy | `IfNotPresent`            |
| `image.tag`        | container image tag        | `0.0.3-gpii.0`            |

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/certmerge-operator
```

The command deploys certmergeoperator on the Kubernetes cluster in the default
configuration. The [configuration](#configuration) section lists the parameters
that can be configured during installation.

## Un-installing the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.
