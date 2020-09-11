#!/bin/bash -e
# release_to_test.sh --- Create a new release.
#
# This script will cut a new release, which involves:
#   - Replacing the Unreleased header in the changelog w/the version & date
#   - Adding a link for the new version to the bottom of the changelog
#   - Updating the revision range of the "Unreleased" link in the changelog
#   - Revving the projects version from a dev version to a proper release
#   - Commiting the above changes to develop, tag the release, and push to origin
#     + this action will initiate a new build of the tagged release
#   - Prepping the CHANGELOG for the next patch release on develop
#
#
# GitLab's Environment Variables
# ------------------------------
#
# CI_PROJECT_PATH:  The namespace with project name
# GITLAB_USER_EMAIL:  The email of the user who that triggered the build.
SCRIPT_DIR=$(cd $(dirname $0); pwd)
TODAY=`date +"%Y-%m-%d"`
GIT_MERGE_AUTOEDIT=no

# include common utilities
test -f $SCRIPT_DIR/functions && . $SCRIPT_DIR/functions


# 1. Initialize docker
start_and_initialize_docker
docker info


# 2. setup git
git_init $CI_PROJECT_PATH $GITLAB_USER_EMAIL


# 3. Calculate next version
#
# NOTE: this assumes that you are revving a 1.0.x patch and not a major or
#       minor release. For those, you will also need to change the
#      `ref/tags/<MAJOR>.<MINOR>*` reference below to match the version you
#       are working with.
LATEST_TAG=$(determine_latest_git_tag "1.0")


# default to v1.0.0 if there are no tags
if [ -z "$LATEST_TAG" ]; then LATEST_TAG=v1.0.0; fi

# determine the current version
BASE_LIST=(`echo $(py_app_version) | tr '.' ' '`)
V_MAJOR=${BASE_LIST[0]}
V_MINOR=${BASE_LIST[1]}
V_PATCH=${BASE_LIST[2]}
V_PATCH_NUMBER=$(echo $V_PATCH | sed 's/dev//')
RELEASE_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH_NUMBER"
NEXT_DEV_VERSION="$V_MAJOR.$V_MINOR.$(($V_PATCH_NUMBER + 1))dev"

echo "Latest tag: $LATEST_TAG"
echo "Current version: $V_MAJOR.$V_MINOR.$V_PATCH"
echo "RELEASE_VERSION: $RELEASE_VERSION"
echo "NEXT_DEV_VERSION: $NEXT_DEV_VERSION"

# 4. set release version
# make sure we are starting from the develop branch
git fetch origin
git checkout develop

# set the project's release version
sed -e "s/VERSION = '\(.*\)'/VERSION = '$RELEASE_VERSION'/" setup.py > setup.py-tmp
if [ -f setup.py-tmp ]; then mv setup.py-tmp setup.py; fi

# update project's changelog to reflect released version and date
changelog_release "$RELEASE_VERSION" "$LATEST_TAG" "$CI_PROJECT_PATH" "$TODAY"


# 5. commit the release changes
git add setup.py CHANGELOG.md
git commit -m "Updated CHANGELOG for release."
# NOTE: In previous iterations of this script, we would do a git push here. We
#       no longer need to push this to develop yet, since it will be pushed to
#       a release tag and the test branch in the following steps. The version
#       will the be bumped to the next patch release and _that_ change will be
#       pushed to develop.


# 6. tag release
#
# NOTE: This will kickoff a CI pipeline that will build the RPM and docker
#       image for the release.
NEW_VERSION_TAG="v$RELEASE_VERSION"
echo "Tagging service with $NEW_VERSION_TAG"

# create releases from the develop branch
git tag -a $NEW_VERSION_TAG -m "Release $NEW_VERSION_TAG (${TODAY})"
git push origin $NEW_VERSION_TAG


# 7. merge and push to test
# NOTE: skipping this step for pymera!


# 8. prep develop for the next dev version

# switch back to develop
git checkout develop
git pull

# set version to next dev patch
sed -e "s/VERSION = '\(.*\)'/VERSION = '$NEXT_DEV_VERSION'/" setup.py > setup.py-tmp
if [ -f setup.py-tmp ]; then mv setup.py-tmp setup.py; fi


# add an "unreleased" section to the top of the CHANGELOG
sed "/## \\[$RELEASE_VERSION\\]/i\\
## [Unreleased]\\
\\
" CHANGELOG.md > CHANGELOG.md-tmp
if [ -f CHANGELOG.md-tmp ]; then mv CHANGELOG.md-tmp CHANGELOG.md; fi

git add setup.py CHANGELOG.md
git commit -m "[CI] Updated changelog for development of $NEXT_DEV_VERSION."
git push
