#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
RUBY=$1
NODE=$2
BUILD_DIR=${DIR}/../build/snap/ruby

docker build --build-arg RUBY=$RUBY --build-arg NODE=$NODE -t syncloud .
docker create --name=ruby syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export ruby -o syncloud.tar
tar xf syncloud.tar
rm -rf syncloud.tar
cp ${DIR}/bin/* ${BUILD_DIR}/bin
