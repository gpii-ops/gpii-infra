# istio-gke-helper chart

This chart is to configure additional properties (like Pod Disruption Budgets) for
GKE's deployment of Istio.

## Configuration

The following table lists the configurable parameters of the chart and their
default values.

| Parameter         | Description                                        | Default                                                   |
|-------------------|----------------------------------------------------|-----------------------------------------------------------|
| `components`      | List of Istio components and their metadata labels | `egressgateway, ingressgateway, pilot, policy, telemetry` |
| `maxUnavailable`  | `maxUnavailable` value for PodDisruptionBudgets    | `1`                                                       |

## Installing the Chart

To install the chart with the release name `my-release`:

```sh
$ helm install --name my-release
path_to_chart/istio-gke-helper
```

The command deploys istio-gke-helper on the Kubernetes cluster in the
default configuration. The [configuration](#configuration) section lists the
parameters that can be configured during installation.

## Un-installing the Chart

To uninstall/delete the `my-release` deployment:

```sh
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.
