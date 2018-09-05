#!/usr/bin/env bash

cd `dirname $0`

#
# Clean out any previous artifacts.
#
rm -rf ./builds ./elm-stuff ./node_modules ./npm-debug.log* ./src/js/CronPixie.js ./src/js/build.js

#
# Set up local tools.
#
npm install --no-optional --no-audit
