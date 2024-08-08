#!/bin/bash
set -ex

REGISTRY="localhost"
PORTABUILDER_IMAGE_PREFIX="portabuilder"
PORTABUILDER_SQUASHFS_TOOLS_IMAGE="${PORTABUILDER_IMAGE_PREFIX}-squashfs-tools"

docker buildx build --file Dockerfile.squashfs-tools --tag ${REGISTRY}/${PORTABUILDER_SQUASHFS_TOOLS_IMAGE}:latest .