# service-account-assigner chart

K8s-gke-service-account-assigner provides Google Service Account Tokens to
containers running inside a kubernetes cluster based on annotations.

This is achieved by acting as an proxy between pods and Google instance metadata
API. See https://github.com/imduffy15/k8s-gke-service-account-assigner for more
details.

## Configuration

The following table lists the configurable parameters of the chart and their
default values.

| Parameter               | Description                                    | Default                                          |
|-------------------------|------------------------------------------------|--------------------------------------------------|
| `image.repository`      | container image repository                     | `gpii/k8s-gke-service-account-assigner`          |
| `image.pullPolicy`      | container image PullPolicy                     | `IfNotPresent`                                   |
| `image.tag`             | container image tag                            | `master-gpii.1`                                  |
| `defaultServiceAccount` | default service account to be assigned to pods | `default`                                        |
| `defaultScopes`         | list of default scopes to be assigned to pods  | `https://www.googleapis.com/auth/cloud-platform` |

## Installing the Chart

GKE nodes have to use service account with
`roles/iam.serviceAccountTokenCreator` role on all service accounts that are to
be used by K8s pods and with `https://www.googleapis.com/auth/cloud-platform`
scope enabled (see https://github.com/imduffy15/k8s-gke-service-account-assigner
for more details).

To install the chart with the release name `my-release`:

```sh
$ helm install --name my-release
path_to_chart/service-account-assigner
```

The command deploys service-account-assigner on the Kubernetes cluster in the
default configuration. The [configuration](#configuration) section lists the
parameters that can be configured during installation.

## Un-installing the Chart

To uninstall/delete the `my-release` deployment:

```sh
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and
deletes the release.
