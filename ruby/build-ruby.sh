#!/bin/bash -e


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=$1
PREFIX=/build

apt update
apt install -y gnupg2 curl procps

command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -

curl -sSL https://get.rvm.io | bash -s stable --path ${PREFIX}
source ${PREFIX}/scripts/rvm
rvm install ${VERSION} --movable

mv /build/rubies/ruby-* /current
rm -rf /build
rm -rf /tmp/*
rm /etc/rvmrc
rm /etc/profile.d/rvm.sh
