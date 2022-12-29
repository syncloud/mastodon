#!/bin/sh -xe

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

VERSION=$1

BUILD_DIR=${DIR}/../build/snap/postgresql

docker build --build-arg VERSION=$VERSION -t syncloud .
docker run syncloud postgres --help
docker create --name=postgres syncloud
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export postgres -o postgres.tar
tar xf postgres.tar
rm -rf postgres.tar
PGBIN=$(echo usr/lib/postgresql/*/bin)
mv $PGBIN/postgres $PGBIN/postgres.bin
mv $PGBIN/pg_dump $PGBIN/pg_dump.bin
rm -rf var
rm -rf usr/lib/*/perl
rm -rf usr/lib/*/perl-base
rm -rf usr/lib/*/dri
rm -rf usr/lib/*/mfx
rm -rf usr/lib/*/vdpau
rm -rf usr/lib/*/gconv
rm -rf usr/lib/*/lapack
rm -rf usr/lib/gcc
rm -rf usr/lib/git-core
rm -rf usr/share

cp $DIR/bin/* bin
cp $DIR/pgbin/* $PGBIN
