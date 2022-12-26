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

apt update
apt install -y git imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git-core \
                     g++ libprotobuf-dev protobuf-compiler pkg-config gcc autoconf \
                     bison build-essential libssl-dev libyaml-dev libreadline6-dev \
                     zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
                     libidn11-dev libicu-dev libjemalloc-dev

export PATH=$PATH:/current/bin
cd /mastodon

bundle config deployment 'true'
bundle config without 'development test'
bundle install -j$(getconf _NPROCESSORS_ONLN)

yarn install --pure-lockfile
RAILS_ENV=production OTP_SECRET=1 SECRET_KEY_BASE=2 bundle exec rake assets:precompile
yarn cache clean
npm cache clean --force
apt remove -y git-core g++ gcc autoconf build-essential
apt autoremove -y
rm -rf /var/lib/apt/lists/*

ln -s /var/snap/mastodon/current/config/.env.production .env.production

sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' /current/bin/bundle
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' vendor/bundle/ruby/*/bin/*
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' bin/rails
