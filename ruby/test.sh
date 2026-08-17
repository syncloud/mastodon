#!/bin/bash -ex
DIR=$( cd "$( dirname "$0" )" && pwd )
cd $DIR/../build/snap/ruby
export RAILS_ENV=production
find . -name bundler
./bin/ruby.sh -e 'puts "Hello"'
./bin/ruby.sh -e "puts $:"
./bin/ruby.sh -e 'puts Gem.path'
./bin/ruby.sh -e "require 'bundler/setup'"
./bin/ruby.sh -e 'require "prism"; raise "stale prism #{Prism::VERSION} shadowing the bundled one" unless defined?(Prism::CurrentVersionError)'
#./bin/ruby.sh mastodon/bin/rails
./bin/node.sh -e 'console.log("test")'

test -f mastodon/streaming/index.js
for dep in express ioredis pg ws; do
  test -d mastodon/node_modules/$dep || test -d mastodon/streaming/node_modules/$dep
done

test -d mastodon/public/assets
test -d mastodon/public/packs

./bin/file -b --mime $DIR/../test/csv/following.csv
./bin/ffmpeg --help
./bin/convert --help
./bin/ffplay --help
./bin/ffprobe --help
./bin/identify -help

