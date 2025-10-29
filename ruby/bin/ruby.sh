#!/bin/bash -xe
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib)
LIBS=$LIBS:$(echo ${DIR}/usr/lib)
LIBS=$LIBS:$(echo ${DIR}/usr/local/lib)
LIBS=$LIBS:$(echo ${DIR}/usr/lib/ruby/*.*.*/*-linux-*)
#export LD_PRELOAD=$(readlink -f ${DIR}/usr/lib/*-linux-gnu*/libjemalloc.so)
export GEM_HOME="$(echo $DIR/usr/lib/ruby/gems/*.*.*)"
export GEM_PATH="$GEM_HOME"
export PATH="$GEM_HOME/bin:$PATH"
RUBYLIB="$(echo $DIR/usr/lib/ruby/*.*.*)"
export RUBYLIB="$RUBYLIB:$(echo $DIR/usr/lib/ruby/*.*.*/*-linux-*)"
exec ${DIR}/lib*/ld-*.so* --library-path $LIBS ${DIR}/usr/bin/ruby "$@"
