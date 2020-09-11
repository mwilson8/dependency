#!/bin/sh
# publish_docker.sh --- Publish the project's Docker image.
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
# To publish a local docker image =using this script from the project root:
#
#     CI=true scripts/publish_docker.sh
#
# > *NOTE*: Publishing images is typically left as a CI only action. To override
# > this, you can set the `CI` environment variable to a non-empty value.
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
# Publish
# --------------------
IMAGE_TAG=$(determine_docker_tag $CI_COMMIT_TAG)

# publish image
if [ -n "$CI" ]; then
  # workaround to support non-cached docker images in the build pipeline
  if ! docker image inspect ${IMAGE_NAME}:${IMAGE_TAG} >/dev/null 2>&1; then
    # *NOTE*: this is useful for when the docker build and publish steps are
    #         separated, but do not use a shared docker registry on the host.
    if [ -f dist/dependency-${IMAGE_TAG}.tar.gz ]; then
      docker load -i dist/dependency-${IMAGE_TAG}.tar.gz
    else
      echo "Unable to find docker image artifact"
    fi
  fi

  docker push ${IMAGE_NAME}:${IMAGE_TAG}
fi
