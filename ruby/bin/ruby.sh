#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib)
LIBS=$LIBS:$(echo ${DIR}/usr/lib)
LIBS=$LIBS:$(echo ${DIR}/usr/local/lib)
#export LD_PRELOAD=$(readlink -f ${DIR}/usr/lib/*-linux-gnu*/libjemalloc.so)
# Add this to your script before running Rails
#export GEM_HOME="$(ls $DIR/usr/lib/ruby/gems/*/)"
#export GEM_PATH="$GEM_HOME"
#export PATH="$GEM_HOME/bin:$PATH"
exec ${DIR}/lib*/ld-*.so* --library-path $LIBS ${DIR}/usr/bin/ruby "$@"
