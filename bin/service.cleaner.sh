#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
$DIR/bin/wait-for-db.sh
while true; do
  echo "cleaning"
  snap run mastodon.tootctl media remove --prune-profiles --include-follows --days 1
  snap run mastodon.tootctl preview_cards remove --days 1
  snap run mastodon.tootctl statuses remove --days 1
  snap run mastodon.tootctl accounts cull
  snap run mastodon.tootctl accounts prune
  echo "sleeping for 24h"
  sleep 24h
done
