#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/node
docker build --build-arg VERSION=$VERSION -t syncloud .
docker run syncloud nodejs --help
docker create --name=nodejs syncloud
mkdir -p ${BUILD_DIR}/bin
cd ${BUILD_DIR}
docker export nodejs -o nodejs.tar
tar xf nodejs.tar
rm -rf nodejs.tar
cp ${DIR}/node.sh ${BUILD_DIR}/bin
rm -rf ${BUILD_DIR}/usr/src
