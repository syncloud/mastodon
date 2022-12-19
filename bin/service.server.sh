#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

function wait_for_db() {
    started=0
    echo "waiting for mastodon db"
    set +e
    for i in $(seq 1 30); do
      ${DIR}/bin/psql.sh -c "select 1;" mastodon
      if [[ $? == 0 ]]; then
        started=1
        break
      fi
      echo "Tried $i times. Waiting 5 secs..."
      sleep 5
    done
    set -e
    if [[ $started == 0 ]]; then
        echo "timeout waiting for mastodon db"
        exit 1
    fi
    echo "done waiting for mastodon db"
}

wait_for_db
exec /snap/mastodon/current/bin/mastodon
