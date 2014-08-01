#!/usr/bin/env bash

# Record the current dependencies and binaries

DATE=$(date)
TIMESTAMP=$(date +"%s")
BRANCH=$(git rev-parse --abbrev-ref HEAD)
BUILT_FILES="node_modules build"

# Remove the compilation/testing dependencies.
# (Assume this is run after building and testing)
DEV_PACKAGES=$(node -e 'console.log(Object.keys(require("./package.json").devDependencies).join(" "))')
npm uninstall $DEV_PACKAGES

# create a temporary branch with the current dependencies and binaries
git checkout -b build-$TIMESTAMP
git add --all --force $BUILT_FILES
git commit -m "copy $BUILT_FILES from $BRANCH"

# merge the temporary branch into the build branch
git branch build || echo "build branch already exists"
git checkout build --force
git merge build-$TIMESTAMP --strategy=subtree -m "Build as of $DATE"
git branch -D build-$TIMESTAMP

# restore the original branch
git checkout $BRANCH
git checkout build -- $BUILT_FILES
git rm -r --cached $BUILT_FILES
