#!/bin/sh -e

for i in $(seq 1 10); do
  if apk add --no-cache "$@"; then
    exit 0
  fi
  echo "retry apk"
  sleep 5
done

echo "apk failed"
exit 1
