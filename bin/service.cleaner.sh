#!/bin/bash -e

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
