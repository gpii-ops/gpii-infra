#!/usr/bin/env sh

# This script verifies that only one version of exekube is being used across the project

EXCLUDE_DIRS=".git"
IMAGE_REGEX="gpii/exekube:\d+\.\d+\.\d+-google_gpii\.\d+"

images=$(find . \( -name "$EXCLUDE_DIRS" -prune \) -o -type f -exec grep -h -o -E "$IMAGE_REGEX" {} \; | sort -u)
images_count=$(echo "$images" | wc -l | awk '{ print $1 }')

if [ "$images" = "" ]; then
  echo "Can't find any matches, skipping..."
elif [ "$images_count" -eq 1 ]; then
  echo "Check passed!"
  echo
  echo "Only $(echo "$images" | tr -d '\n') is being used."
else
  images_with_files=$(find . \( -name "$EXCLUDE_DIRS" -prune \) -o -type f -exec grep -n -o -E -H "$IMAGE_REGEX" {} \; | sort -u)

  echo "Check failed!"
  echo
  echo "$images_count image versions:"
  echo "$images"
  echo
  echo "Found in files:"
  echo "$images_with_files"
  exit 1
fi
