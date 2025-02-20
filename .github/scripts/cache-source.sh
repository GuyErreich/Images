#!/bin/bash

IMAGE_NAME=$1 # First argument to script

if [[ "${GITHUB_BASE_REF}" == "dev" ]]; then
  CACHE_TAG="v*-dev"
elif [[ "${GITHUB_BASE_REF}" == "staging" ]]; then
  CACHE_TAG="v*-staging"
else
  CACHE_TAG="v*"
fi

# Fetch latest tag matching the cache pattern
CACHE_IMAGE=$(git tag -l "${IMAGE_NAME}-$CACHE_TAG" --sort=-v:refname | head -n 1)
CACHE_FROM="ghcr.io/${GITHUB_REPOSITORY_OWNER}/${IMAGE_NAME}:${CACHE_IMAGE:-latest}"

echo "CACHE_FROM=$CACHE_FROM" >> "$GITHUB_ENV"
echo "Using Cache from: $CACHE_FROM"
