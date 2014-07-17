#!/bin/sh -x

# Install dependencies

if [ ! -e "./node_modules/" ]; then
    # this script is normally run by `npm install`
    # if NPM hasn't been run yet, run it now
    exec npm install
fi

# install bower components
bower install --config.interactive=false

# build the production client
brunch build --production
