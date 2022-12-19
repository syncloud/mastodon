#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
docker build --build-arg VERSION=$VERSION -t syncloud .
docker run syncloud nodejs --help
docker create --name=nodejs syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export nodejs -o nodejs.tar
tar xf nodejs.tar
rm -rf nodejs.tar
cp ${DIR}/node.sh ${BUILD_DIR}/bin/
${BUILD_DIR}/bin/node.sh --help
ls -la ${BUILD_DIR}/bin
rm -rf ${BUILD_DIR}/usr/src
