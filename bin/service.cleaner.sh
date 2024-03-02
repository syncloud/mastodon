#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
$DIR/wait-for-db.sh
while true; do
  echo "cleaning"
  $DIR/tootctl.sh media remove --prune-profiles --include-follows --days 1
  $DIR/tootctl.sh preview_cards remove --days 1
  $DIR/tootctl.sh statuses remove --days 1
  $DIR/tootctl.sh accounts cull
  $DIR/tootctl.sh accounts prune
  echo "sleeping for 24h"
  sleep 24h
done
