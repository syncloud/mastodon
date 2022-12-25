#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/ruby/mastodon
export RAILS_ENV=production
export DB_POOL=25
export MALLOC_ARENA_MAX=2
while diff /snap/mastodon/current/version /var/snap/mastodon/current/version; do
    echo "waiting for db"
    sleep 2
done
exec $DIR/ruby/current/bin/bundle exec sidekiq -c 25
