#!/usr/bin/env bash -x

# Record the current dependencies and binaries

export GIT_AUTHOR_NAME="Release Bot"
export GIT_AUTHOR_EMAIL="release-bot@no-email.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

BUILT_FILES="node_modules build"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
BUILD_PARENT=$(git rev-parse -q --verify build/$BRANCH)

# Remove the compilation/testing dependencies.
# (Assume this is run after building and testing)
DEV_MODULES=$(node -e 'console.log(Object.keys(require("./package.json").devDependencies).join(" "))')
npm uninstall $DEV_MODULES

# Record current checkout plus "$BUILT_FILES" to build branch.
for FILE in $BUILT_FILES; do
    git add --all --force $FILE
done
git update-ref refs/heads/build/$BRANCH $(
    git commit-tree \
        ${BUILD_PARENT:+-p $BUILD_PARENT} \
        -p HEAD \
        -m "Build on $(uname -a)" \
        $(git write-tree)
)

# Reset index to HEAD
git reset
