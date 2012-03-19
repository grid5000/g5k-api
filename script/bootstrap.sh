#!/usr/bin/env bash

set -x
set -e

RACK_ENV=test bundle exec rake db:setup
RACK_ENV=test bundle exec rake db:oar:setup