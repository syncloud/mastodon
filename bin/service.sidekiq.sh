#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/ruby/mastodon
export RAILS_ENV=production
export DB_POOL=25
export MALLOC_ARENA_MAX=2
export LD_PRELOAD=libjemalloc.so
exec $DIR/ruby/current/bin/bundle.sh exec sidekiq -c 25
