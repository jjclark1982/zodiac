#!/bin/sh -x

# Install dependencies

if [ ! -e "./node_modules/" ]; then
    # this script is normally run by `npm install`
    # if NPM hasn't been run yet, run it now
    exec npm install
fi

# compile docs
[ -x "$(which docco)" ] && docco server/* client/{*,*/*}.coffee

# install sass on production
if [ ! -x "$(which sass)" -a "$(uname)" != "Darwin" ]; then
    export GEM_HOME="${HOME}/.ruby_gems"
    gem install --bindir "bin" --no-rdoc --no-ri sass
fi

# install bower components
bower install

# build the production client
brunch build --production
