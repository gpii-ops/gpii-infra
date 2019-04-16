serviceAccount: "${ service_account }"

image:
  repository: ${k8s_snapshots_repository}
  tag: ${k8s_snapshots_tag}

useClaimName: true
