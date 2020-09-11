#!/bin/sh
# build_rpm.sh --- Builds the project.
#
# Environment Variables
# ---------------------
#
# BUILDER_IMAGE:       The image to use to build the RPM.
# CI_PROJECT_DIR:      The project directory
# CI_PIPELINE_ID:      The pipeline id. This will be used as the build number.
# CI_COMMIT_SHA:       The Git commit hash.
# CI_COMMIT_REF_NAME:  The Git branch.
#
#
# Local Build
# -----------
#
# To build the RPM locally using this script from the project root:
#
#     CI_PROJECT_DIR=`pwd` \
#       CI_PIPELINE_ID=12345678 \
#       scripts/build_rpm.sh
#
# > *NOTE*: The version of the build image may be different. See the
# > `.gitlab.yml` file for the exact verison.
#
# Once the build succeeds, the RPM can be found in the `dist` directory.
BUILDER_IMAGE=cdn-docker.363-283.io/docker/backend:python-3.6-rpm-builder-20190220
TIMESTAMP=$(date -u +%Y%m%d%H%M)
GIT="$(which git)"
SCRIPT_DIR=$(cd $(dirname $0); pwd)
CI_COMMIT_SHA=${CI_COMMIT_SHA:-`$GIT rev-parse HEAD`}

# include common utilities
test -f $SCRIPT_DIR/functions && . $SCRIPT_DIR/functions


# --------------------
# Before Script
# --------------------
start_and_initialize_docker


# --------------------
# Build Script
# --------------------
# 1. Prepare environment variables
#
# NOTE: These are used by the version command in setup.py and need to be exported
export BUILD_NUMBER=${CI_PIPELINE_ID}
export GIT_BRANCH=${CI_COMMIT_REF_NAME}
export GIT_COMMIT=`echo $CI_COMMIT_SHA | cut -c1-8`  # limit the hash to 8 chars


# 2. Ensure the dependencies required by setup.py are met
pip install gitpython==2.1.10


# 3. Generate static assets

# *NOTE*: There are three formats for version numbers reported by python --version:
#
# * prerelease (MAJOR.MINOR.PATCH.dev0
# * release    (MAJOR.MINOR.PATCH)
# * hotfix     (MAJOR.MINOR.PATCH.HOTFIX_NUMBER)
#
# For prereleases and releases, the version of the RPM will be reported as
# MAJOR.MINOR.PREFIX. However, a separate approach will be used to determine
# the release number. Releases will use the format `1.<timestamp>` (e.g.
# 1.201903192048). Prereleases will move the "dev0" portion of the version
# number over to the release number in the format `dev0.<timestamp>` (e.g.
# dev0.201903192048).
#
# Hotfixes are simlar to release, but will employ the four part version
# version number.
proj_version=$(python setup.py --version >&1)

if [[ $proj_version == *.dev0 ]]; then  # prerelease
  releaseNumber=dev0

  # extract project version w/o the prerelease info
  proj_version=$(echo $proj_version | sed 's/.dev0//')

  # temporarily replace the version in setup.py for RPM generation via bdist_rpm
  # NOTE: this is ugly, but there does not seem to another way to set this attribute
  sed -e "s/VERSION = '\(.*\)'/VERSION = '$proj_version'/" setup.py > setup.py-tmp
  if [ -f setup.py-tmp ]; then mv setup.py-tmp setup.py; fi
else  # release or hotfix
  releaseNumber=1
fi

RELEASE_VERSION=${releaseNumber}.${TIMESTAMP}

# ensure that the release version does not end in a dot
if [ `echo ${RELEASE_VERSION} | sed -e "s/^.*\(.\)$/\1/"` == "." ] ; then
    RELEASE_VERSION=${RELEASE_VERSION%?}  # delete the trailing dot
fi

python setup.py version --release $RELEASE_VERSION
python setup.py changelog


# 4. build the RPM
docker pull ${BUILDER_IMAGE}
docker run \
  --rm \
  -i \
  -v ${CI_PROJECT_DIR}/:/usr/src/app \
  -w /usr/src/app \
  -e CI="$CI" \
  -e CI_BUILD_REF=$GIT_COMMIT \
  ${BUILDER_IMAGE} \
  python3.6 setup.py bdist_rpm --release ${RELEASE_VERSION}%{dist}

if [[ $proj_version == *.dev0 ]]; then
  # undo RPM related version manipulation
  git checkout setup.py
fi
