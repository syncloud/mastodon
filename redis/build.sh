#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/redis

while ! docker ps; do
    echo "waiting for docker"
    sleep 2
done

docker build --build-arg VERSION=$VERSION -t syncloud .
docker run syncloud redis-server -v
docker create --name=redis syncloud
mkdir -p ${BUILD_DIR}/bin
cd ${BUILD_DIR}
docker export redis -o syncloud.tar
tar xf syncloud.tar
rm -rf syncloud.tar
cp ${DIR}/bin/* ${BUILD_DIR}/bin
rm -rf ${BUILD_DIR}/usr/src
