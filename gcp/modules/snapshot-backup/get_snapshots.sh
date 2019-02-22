#!/bin/sh

JSON=$(gcloud compute snapshots list --sort-by=~creationTimestamp --limit=2 --filter="name" --format="json(name)")
jq -n "{"snapshots":$JSON}"