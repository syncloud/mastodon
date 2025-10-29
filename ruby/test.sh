#!/bin/bash -ex
DIR=$( cd "$( dirname "$0" )" && pwd )
cd $DIR/../build/snap/ruby
export RAILS_ENV=production
find . -name bundler
./bin/ruby.sh -e 'puts "Hello"'
./bin/ruby.sh -e "puts $:"
./bin/ruby.sh -e 'puts Gem.path'
./bin/ruby.sh -e "require 'bundler/setup'"
#./bin/ruby.sh mastodon/bin/rails
./bin/node.sh -e 'console.log("test")'
./bin/file -b --mime $DIR/../test/csv/following.csv
./bin/ffmpeg --help