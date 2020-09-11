#!/bin/sh
# publish_rpm.sh --- Publish the project's RPM to Chimera's Yum repos.
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# include common utilities
test -f $SCRIPT_DIR/functions && . $SCRIPT_DIR/functions

# --------------------
# Publish RPM
# --------------------

# create a destination for the RPM files
mkdir -p dist/files

# purge old build artifacts
#find dist -type f -mtime 1 -name '*.rpm' -delete

# move the build artifacts
cp `find dist -name *.rpm | grep -v src | grep -v debug` dist/files

# move the RPM(s) up to the AWS S3 staging bucket
aws s3 cp dist/files/*.rpm s3://chimera-yum-repo/staging/6/ --exclude "*" --include "*.rpm"

# Copy release RPM to builds S3 bucket
if [ -n "$CI_COMMIT_TAG" ]; then
  mkdir -p dist/release
  cp `find dist -type f -name '*.rpm' | grep -v src | grep -v debug | grep -v dev0` dist/release
  ls dist/release

  # copy RPM up to the AWS s3 release bucket
  aws s3 cp dist/release s3://chimera-yum-repo/release/6/ --exclude "*" --include "*.rpm"

  # copy to the old/deprecated bucket
  aws s3 cp dist/release s3://chm-builds.363-283.io/ --recursive --exclude "*" --include "*.rpm"
fi

# purge staged files
rm -rf dist/files dist/release
