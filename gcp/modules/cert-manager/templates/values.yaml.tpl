image:
  repository: ${cert_manager_repository}
  tag: ${cert_manager_tag}

createCustomResource: true
useCrdInstallHook: false
webhook:
  enabled: false
podAnnotations:
  accounts.google.com/service-account: "${service_account}"
  accounts.google.com/scopes: "https://www.googleapis.com/auth/cloud-platform"
extraArgs:
  - --issuer-ambient-credentials
