#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/redis
docker build --build-arg VERSION=$VERSION -t syncloud .
docker run syncloud redis-server -v
docker create --name=syncloud syncloud
mkdir -p ${BUILD_DIR}/bin
cd ${BUILD_DIR}
docker export syncloud -o syncloud.tar
tar xf syncloud.tar
rm -rf syncloud.tar
cp ${DIR}/* ${BUILD_DIR}/bin
rm -rf ${BUILD_DIR}/usr/src
