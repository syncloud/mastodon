#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/ruby/mastodon
export RAILS_ENV=production
export SOCKET=/var/snap/mastodon/current/backend.socket
$DIR/bin/wait-for-db.sh
exec $DIR/ruby/current/bin/bundle exec puma -C config/puma.rb
