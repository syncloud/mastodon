#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

cd $DIR/ruby/mastodon
. /var/snap/mastodon/current/config/.env.production
export RAILS_ENV=production
export SOCKET=/var/snap/mastodon/common/web.socket
export LD_PRELOAD=libjemalloc.so
export STREAMING_CLUSTER_NUM=1
exec $DIR/node/bin/node.sh ./streaming
