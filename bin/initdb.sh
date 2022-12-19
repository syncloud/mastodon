#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

# shellcheck source=config/env
. "/var/snap/mastodon/current/config/env"

if [[ "$(whoami)" == "mastodon" ]]; then
    ${DIR}/postgresql/bin/initdb.sh "$@"
else
    sudo -E -H -u mastodon ${DIR}/postgresql/bin/initdb.sh "$@"
fi
