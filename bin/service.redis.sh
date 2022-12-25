#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

exec ${DIR}/redis/bin/redis-server /var/snap/mastodon/current/config/redis.conf
