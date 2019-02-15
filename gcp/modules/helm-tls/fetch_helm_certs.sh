#!/bin/bash

cd /project/live/${ENV}/k8s/kube-system/helm-tls

echo "[helm-tls] Pulling helm-tls TF state..."
state=$(terragrunt state pull 2> /dev/null | jq -r ".modules[].resources | select(length > 0)")
for i in ca_cert helm_cert helm_key tiller_cert tiller_key; do
  content=$(echo "$state" | jq -r ".[\"local_file.${i}\"].primary.attributes.content")
  filename=$(echo "$state" | jq -r ".[\"local_file.${i}\"].primary.attributes.filename")
  if [ "$filename" != "" ]; then
    echo "[helm-tls] Populating ${filename}..."
    mkdir -p $(dirname "${filename}")
    echo "${content}" > "${filename}"
  fi
done
