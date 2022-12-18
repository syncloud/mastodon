#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

# shellcheck source=config/env
. "/var/snap/mastodon/current/config/env"

if [[ "$(whoami)" == "mastodon" ]]; then
    ${DIR}/postgresql/bin/pg_dumpall.sh -p ${PSQL_PORT} -h ${PSQL_DATABASE} "$@"
else
    sudo -E -H -u mastodon ${DIR}/postgresql/bin/pg_dumpall.sh -p ${PSQL_PORT} -h ${PSQL_DATABASE} "$@"
fi
