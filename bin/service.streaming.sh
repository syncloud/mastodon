#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

cd $DIR/ruby/mastodon
export SOCKET=/var/snap/mastodon/current/streaming.socket
export STREAMING_CLUSTER_NUM=1
export NODE_ENV=production
/bin/rm -rf $SOCKET
$DIR/bin/wait-for-db.sh
exec $DIR/ruby/bin/node.sh ./streaming
