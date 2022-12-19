#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
BUILD_DIR=${DIR}/../build/snap/node
cd ${BUILD_DIR}
ls -la bin
./bin/node.sh --help
