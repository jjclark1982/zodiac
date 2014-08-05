#!/usr/bin/env bash -x

# Record the current dependencies and binaries

DATE=$(date)
TIMESTAMP=$(date +"%s")
BRANCH=$(git rev-parse --abbrev-ref HEAD)
BUILT_FILES="node_modules build"
export GIT_AUTHOR_NAME="Release Bot"
export GIT_AUTHOR_EMAIL="release-bot@no-email.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

# Remove the compilation/testing dependencies.
# (Assume this is run after building and testing)
DEV_PACKAGES=$(node -e 'console.log(Object.keys(require("./package.json").devDependencies).join(" "))')
npm uninstall $DEV_PACKAGES

# create a temporary branch with the current dependencies and binaries
git checkout -b build/$TIMESTAMP
for FILE in $BUILT_FILES; do
    git add --all --force $FILE
done
git commit -m "copy built files from $BRANCH on $(uname -a)"

# merge the temporary branch into the build branch
git branch build/$BRANCH || echo "build branch already exists"
git checkout --force build/$BRANCH
git merge build/$TIMESTAMP --strategy=subtree -m "Build as of $DATE"
git branch -D build/$TIMESTAMP

# restore the original branch
git checkout --force $BRANCH
for FILE in $BUILT_FILES; do
    git checkout build/$BRANCH -- $FILE
    git rm -r --cached $FILE
done
exit 0

# may need to automatically edit the .gitignore file
# sed -i.bak '/^\/node_modules/d' .gitignore
# sed -i.bak '/^\/build/d' .gitignore
