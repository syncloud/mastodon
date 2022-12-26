#!/bin/sh -xe

DIR=$( cd "$( dirname "$0" )" && pwd )
DOWNLOAD_URL=https://github.com/syncloud/3rdparty/releases/download
VERSION=$1
ARCH=$(uname -m)

apk add patch

rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build/snap
mkdir -p ${BUILD_DIR}

cd ${DIR}/build

wget ${DOWNLOAD_URL}/nginx/nginx-${ARCH}.tar.gz
tar xf nginx-${ARCH}.tar.gz
mv nginx ${BUILD_DIR}

cd ${DIR}/ruby
wget https://github.com/mastodon/mastodon/archive/refs/tags/v$VERSION.tar.gz
tar xf v$VERSION.tar.gz
mv mastodon-$VERSION mastodon
cd mastodon
for f in ${DIR}/patch/*
do
  patch -p1 < $f
done
