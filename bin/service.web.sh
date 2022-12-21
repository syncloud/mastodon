#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
cd $DIR/ruby/mastodon
export RAILS_ENV=production
export SOCKET=/var/snap/mastodon/common/web.socket
export LD_PRELOAD=libjemalloc.so
exec $DIR/ruby/bin/bundle.sh exec puma -C config/puma.rb
