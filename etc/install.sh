#!/bin/bash
touch /src/foobar
su zodiac -c "cd /src; npm install"
echo -e "export PATH=$PATH:node_modules/.bin" > ~/.profile
source ~/.profile
