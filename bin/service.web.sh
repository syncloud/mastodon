#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/ruby/mastodon
export PATH=$DIR/ruby/bin:$PATH
export RAILS_ENV=production
export SOCKET=/var/snap/mastodon/current/backend.socket
$DIR/bin/wait-for-db.sh
exec $DIR/ruby/bin/bundle exec puma -C config/puma.rb
