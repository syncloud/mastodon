#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

cd $DIR/ruby/mastodon
export SOCKET=/var/snap/mastodon/common/web.socket
export STREAMING_CLUSTER_NUM=1
exec $DIR/node/bin/node.sh ./streaming
