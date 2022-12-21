#!/bin/bash -ex
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/usr/local/lib)
PRELOAD=$(echo ${DIR}/usr/lib/*-linux-gnu*/libjemalloc.so)
${DIR}/lib*/*-linux*/ld-*.so --library-path $LIBS ${DIR}/current/bin/ruby "$@"

