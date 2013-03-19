#!/bin/sh
set -eu

bundle install --quiet --path "${HOME}/bundles/${JOB_NAME}" --deployment
exec bundle exec ruby test/test_authwrapper.rb
