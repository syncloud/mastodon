#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/python
docker build --build-arg VERSION=$VERSION -t syncloud .
docker run syncloud python --help
docker create --name=python syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export python -o python.tar
tar xf python.tar
rm -rf python.tar
cp ${DIR}/python ${BUILD_DIR}/bin/
ls -la ${BUILD_DIR}/bin
rm -rf ${BUILD_DIR}/usr/src
