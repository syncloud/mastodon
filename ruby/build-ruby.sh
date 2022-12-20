#!/bin/bash -e


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=$1
PREFIX=/ruby

apt update
apt install -y gnupg2 curl

command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -


curl -sSL https://get.rvm.io | bash -s stable --path ${PREFIX}
source ${PREFIX}/scripts/rvm
rvm install ${VERSION} --movable

ls -la /ruby/rubies
ls -la /ruby/rubies/*/
ls -la /ruby/rubies/*/bin

rm /etc/rvmrc
rm /etc/profile.d/rvm.sh
