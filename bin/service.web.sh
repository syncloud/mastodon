#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/ruby/mastodon
. /var/snap/mastodon/current/config/.env.production
export RAILS_ENV=production
export SOCKET=/var/snap/mastodon/common/web.socket
exec $DIR/ruby/current/bin/bundle exec puma -C config/puma.rb
