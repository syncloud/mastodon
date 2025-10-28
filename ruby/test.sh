#!/bin/bash -ex
DIR=$( cd "$( dirname "$0" )" && pwd )
cd $DIR/../build/snap/ruby
export RAILS_ENV=production
./bin/ruby.sh -e 'puts "Hello"'
./bin/ruby.sh -e "require 'bundler/setup'"
./bin/ruby.sh mastodon/bin/rails
./bin/node.sh -e 'console.log("test")'
./bin/file -b --mime $DIR/../test/csv/following.csv
