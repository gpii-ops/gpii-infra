replicaCount: ${replica_count}

image:
  repository: ${flowmanager_repository}
  checksum: ${flowmanager_checksum}

acme:
  clouddnsProject: ${project_id}
  server: "${acme_server}"
  email: "${acme_email}"

dnsNames:
- flowmanager.${domain_name}

datasourceHostname: "http://${couchdb_admin_username}:${couchdb_admin_password}@couchdb-svc-couchdb.gpii.svc.cluster.local"

enableStackdriverTrace: true

resources:
  requests:
    cpu: ${requests_cpu}
    memory: ${requests_memory}
  limits:
    cpu: ${limits_cpu}
    memory: ${limits_memory}
