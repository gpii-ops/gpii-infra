# administraton-tasks chart

## Namespaces

### Create and label namespaces

```yaml
namespaces:
  - name: team1
    secure: false
    labels:
      name: team1
      mylabel: team1-label
```

### Create security-hardened namespaces

> :warning: When you specify `secure: true`, pods in the namespace will not be able to communicate unless you create a NetworkPolicy to allow that traffic.

Specify `secure: true` in order to create:

- A default-deny-all NetworkPolicy for all pods in the namespaces (Ingress and Egress)
- An allow-dns-access NetworkPolicy (so that pods in the namespace can access `kube-dns`)

```yaml
namespaces:
  - name: team1
    secure: true
```

## Assign cluster administrators

You can assign users to have `cluster-admin` role for all namespaces:

```yaml
clusterAdmins:
  create: true
  users:
    - user@example.com
```

## Assign roles to the Kubernetes Dashboard

```yaml
dashboardPermissions:
  create: true
  clusterRoles:
    - view
    - secret-lister
    - cluster-object-viewer
```
