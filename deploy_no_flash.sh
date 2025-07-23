#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Function ---
run_command() {
  echo "Running: $@"
  "$@"
}

# --- Main Script ---

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//' | xargs)
fi

# Check for required environment variables
if [ -z "${CR_PAT}" ]; then
  echo "Error: CR_PAT is not set."
  exit 1
fi

if [ -z "${CR_USER}" ]; then
  echo "Error: CR_USER is not set."
  exit 1
fi

# Define the version for the Docker Image
VERSION=${BASE_FLASH_VERSION:-"1.0.0"}
echo "Building Flash Attention container version ${VERSION}"

IMAGE_NAME="ghcr.io/reenvision-ai/base-image"
IMAGE_WITH_VERSION="${IMAGE_NAME}:${VERSION}"
LATEST_IMAGE="${IMAGE_NAME}:latest"

# Login to GitHub Container Registry using podman
echo "Running: podman login ghcr.io -u ${CR_USER} --password-stdin"
echo "${CR_PAT}" | podman login ghcr.io -u "${CR_USER}" --password-stdin

# Build the image with podman
run_command podman build  --build-arg WITH_FLASH=false -t "${IMAGE_WITH_VERSION}" .

# Push the image to the registry
run_command podman push "${IMAGE_WITH_VERSION}"

# Tag and push the 'latest' tag if the version is not 'latest' and not a beta version
if [ "${VERSION}" != "latest" ] && [[ "${VERSION}" != *"beta"* ]]; then
  # Tag the image as latest
  run_command podman tag "${IMAGE_WITH_VERSION}" "${LATEST_IMAGE}"

  # Push the latest image
  run_command podman push "${LATEST_IMAGE}"
fi

echo "Script completed successfully."