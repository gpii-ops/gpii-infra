# certmerge-operator-crd chart

This is complementary chart to certmerge-operator one, required due to Helm's
inability to handle CRDs definition and actual custom resources creation at the
same chart (see https://github.com/helm/helm/issues/2994 for details).

## Configuration

The following table lists the configurable parameters of the chart and their
default values.

| Parameter     | Description                | Default  |
|---------------|----------------------------|--------- |
| `secretLists` | list of secretlist definitions - custom resource of type CertMerge will be created, with corresponding secretlist spec, for each item | `[]` |



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
