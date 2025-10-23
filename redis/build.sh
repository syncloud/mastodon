#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/redis
mkdir -p $BUILD_DIR
cp -r /usr ${BUILD_DIR}

ls -la /lib/*-linux*
ls -la /usr/lib/*-linux*

ls -la /usr/lib/*-linux*/ld-*.so.*
ls -la /lib/*-linux*/ld-*.so.*

cd ${BUILD_DIR}
ln -s usr/lib lib
ls -la
ls -la lib/
ls -la usr/lib/*-linux*/ld-*.so.*
ls -la lib/*-linux*/ld-*.so.*

cd $DIR
cp -r ${DIR}/bin ${BUILD_DIR}/bin
