#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/ruby
docker build --build-arg VERSION=$VERSION -t syncloud .
docker run syncloud ruby --help
docker create --name=syncloud syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export syncloud -o syncloud.tar
tar xf syncloud.tar
rm -rf syncloud.tar
cp ${DIR}/bin/* ${BUILD_DIR}/bin
