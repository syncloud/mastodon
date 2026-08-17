#!/bin/sh -e

URL=$1
TARGET=$2

for i in $(seq 1 10); do
  if wget -T 60 -O "${TARGET}" "${URL}"; then
    exit 0
  fi
  echo "retry download ${URL}"
  rm -f "${TARGET}"
  sleep 10
done

echo "failed to download ${URL}"
exit 1
