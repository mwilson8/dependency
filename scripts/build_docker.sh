#!/bin/sh
# build_docker.sh --- Build the project's Docker image.
#
# GitLab's Environment Variables
# ------------------------------
#
# CI:              A flag indicating if the project was run in a CI env.
# CI_COMMIT_TAG:   The current tag, if one exists
#
# Local Build
# -----------
#
# To build the docker image locally using this script from the project root:
#
#     scripts/build_docker.sh
IMAGE_NAME=cdn-docker.363-283.io/chimera/dependency
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# include common utilities
test -f $SCRIPT_DIR/functions && . $SCRIPT_DIR/functions


# --------------------
# Before Script
# --------------------
start_and_initialize_docker
docker info


# --------------------
# Build
# --------------------
IMAGE_TAG=$(determine_docker_tag $CI_COMMIT_TAG)

# run changelog and version
python setup.py changelog version


# build image
docker build --build-arg CI=${CI} -t ${IMAGE_NAME}:${IMAGE_TAG} .

# save docker image
if [ -n "$CI" ]; then
  mkdir -p dist
  docker save -o dist/dependency-${IMAGE_TAG}.tar.gz  ${IMAGE_NAME}:${IMAGE_TAG}
fi
