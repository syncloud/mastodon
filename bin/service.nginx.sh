#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

/bin/rm -f /var/snap/mastodon/common/web.socket
exec ${DIR}/nginx/sbin/nginx -c /snap/mastodon/current/config/nginx.conf -p ${DIR}/nginx -g 'error_log syslog:server=unix:/dev/log warn;'
