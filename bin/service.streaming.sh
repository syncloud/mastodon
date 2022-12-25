#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

cd $DIR/ruby/mastodon
export SOCKET=/var/snap/mastodon/common/web.socket
export STREAMING_CLUSTER_NUM=1
while diff /snap/mastodon/current/version /var/snap/mastodon/current/version; do
    echo "waiting for db"
    sleep 2
done
exec $DIR/ruby/bin/node.sh ./streaming
