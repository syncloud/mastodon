#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/ruby/mastodon
export PATH=$PATH:$DIR/ruby/bin
export RAILS_ENV=production
export DB_POOL=25
export MALLOC_ARENA_MAX=2
$DIR/bin/wait-for-db.sh
exec $DIR/ruby/usr/bin/bundle exec sidekiq -c 25
