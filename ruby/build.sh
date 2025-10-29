#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1

BUILD_DIR=${DIR}/../build/snap/ruby
mkdir -p ${BUILD_DIR}

cd ${DIR}/../build
wget https://github.com/mastodon/mastodon/archive/refs/tags/v${VERSION}.tar.gz
tar xf v${VERSION}.tar.gz
cd mastodon-${VERSION}

apk add \
ruby \
nodejs \
ruby-bundler \
ruby-dev \
build-base \
libpq-dev \
libidn-dev \
icu-dev \
yaml-dev \
zlib-dev \
npm \
vips-dev \
git

export RAILS_ENV=production
export NODE_ENV=production
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

bundle config deployment 'true'
bundle config without 'development test exclude'
bundle config set silence_root_warning true
bundle install -j$(getconf _NPROCESSORS_ONLN)

npm install -g corepack
corepack enable

yarn install

ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=precompile_placeholder \
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=precompile_placeholder \
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=precompile_placeholder \
  OTP_SECRET=precompile_placeholder \
  SECRET_KEY_BASE=precompile_placeholder \
  bundle exec rails assets:precompile

apk del \
nodejs \
build-base \
npm \
git
find / -name bundler
ruby -e 'puts Gem.path'
ruby -e "puts $:"
ruby bin/rails

ln -s /var/snap/mastodon/current/config/.env.production .env.production
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' /usr/bin/bundle
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' vendor/bundle/ruby/*/bin/*
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' bin/rails
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' bin/tootctl

cd public
ln -s /var/snap/mastodon/current/system system

mv ${DIR}/../build/mastodon-${VERSION} ${BUILD_DIR}/mastodon
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
mkdir ${BUILD_DIR}/bin
cp ${DIR}/bin/* ${BUILD_DIR}/bin
