# kube-state-metrics chart

Kube-state-metrics is an add-on agent to generate and expose cluster-level metrics.

See https://github.com/kubernetes/kube-state-metrics for usage details.

## Configuration

The following table lists the configurable parameters of the chart and their
default values.

| Parameter                           | Description                       | Default                                     |
|-------------------------------------|-----------------------------------|---------------------------------------------|
| `image.repository`                  | container image repository        | `quay.io/coreos/kube-state-metrics`         |
| `image.pullPolicy`                  | container image pullPolicy        | `IfNotPresent`                              |
| `image.tag`                         | container image tag               | `v1.9.5`                                    |
| `prometheus-to-sd.image.repository` | prometheus-to-sd image repository | `gcr.io/google-containers/prometheus-to-sd` |
| `prometheus-to-sd.image.pullPolicy` | prometheus-to-sd image pullPolicy | `IfNotPresent`                              |
| `prometheus-to-sd.image.tag`        | prometheus-to-sd image tag        | `v0.9.2`                                    |

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release path_to_chart/kube-state-metrics
```

The command deploys kube-state-metrics on the Kubernetes cluster in the default
configuration. The [configuration](#configuration) section lists the parameters
that can be configured during installation.

## Un-installing the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.
