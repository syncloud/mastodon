#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/redis
mkdir -p $BUILD_DIR
cp -r /usr ${BUILD_DIR}
cd ${BUILD_DIR}
ln -s usr/lib lib
cd $DIR
cp -r ${DIR}/bin ${BUILD_DIR}/bin
