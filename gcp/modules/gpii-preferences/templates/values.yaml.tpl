replicaCount: ${replica_count}

image:
  repository: ${preferences_repository}
  checksum: ${preferences_checksum}

datasourceHostname: "http://${couchdb_admin_username}:${couchdb_admin_password}@couchdb-svc-couchdb.gpii.svc.cluster.local"

enableStackdriverTrace: true
credentialsSecretName: ${service_account_id}-credentials

resources:
  requests:
    cpu: ${requests_cpu}
    memory: ${requests_memory}
  limits:
    cpu: ${limits_cpu}
    memory: ${limits_memory}
