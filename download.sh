#!/bin/sh -xe

DIR=$( cd "$( dirname "$0" )" && pwd )
VERSION=$1

rm -rf ${DIR}/build
BUILD_DIR=${DIR}/build/snap
mkdir -p ${BUILD_DIR}
cd ${DIR}/ruby
wget https://github.com/mastodon/mastodon/archive/refs/tags/v$VERSION.tar.gz
tar xf v$VERSION.tar.gz
mv mastodon-$VERSION mastodon
