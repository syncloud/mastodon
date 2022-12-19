#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/mastodon
export RAILS_ENV=production
export DB_POOL=25
export MALLOC_ARENA_MAX=2
export LD_PRELOAD=libjemalloc.so
exec $DIR/ruby/usr/local/bin/bundle exec sidekiq -c 25
