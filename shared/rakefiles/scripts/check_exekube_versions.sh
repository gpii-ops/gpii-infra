#!/usr/bin/env sh

# This script verifies that only one version of exekube is being used across the project

IMAGE_PATTERN="gpii/exekube:\d+\.\d+\.\d+-google_gpii\.\d+"
EXCLUDE_DIRS=".git"

images=$(grep -r -o -E -h "$IMAGE_PATTERN" --exclude-dir "$EXCLUDE_DIRS" . | sort -u)
images_count=$(echo "$images" | wc -l | bc)

if [ "$images_count" -eq 1 ]; then
  echo "Check passed!"
  echo
  echo "Only $(echo "$images" | tr -d '\n') is being used."
else
	echo "Check failed!"
	echo
	echo "$images_count image versions:"
	echo "$images"
	echo
	echo "Found in files:"
	grep -r -o -E -n "$IMAGE_PATTERN" --exclude-dir "$EXCLUDE_DIRS" . | sort -u
	exit 1
fi
