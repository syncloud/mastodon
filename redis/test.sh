#!/bin/bash -xe

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/redis
cd ${BUILD_DIR}
./bin/redis-server.sh -v
