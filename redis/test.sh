#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/redis
ls -la $BUILD_DIR
ls -la $BUILD_DIR/lib/
ls -la $BUILD_DIR/lib/*-linux*/ld-*.so.*
$BUILD_DIR/bin/redis.sh -v
