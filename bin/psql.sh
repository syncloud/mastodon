#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )


# shellcheck source=config/env
. "/var/snap/mastodon/current/config/env"

${DIR}/postgresql/bin/psql.sh -U mastodon -p ${PSQL_PORT} -h ${PSQL_DATABASE} "$@"
