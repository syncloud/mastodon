#!/bin/bash -ex


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

VERSION=$1
PREFIX=/build

apt update
apt install -y gnupg2 curl procps file

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
                     libidn11-dev libicu-dev libjemalloc-dev libvips-dev

export PATH=$PATH:/current/bin
cd /mastodon

export RAILS_ENV="production"
export NODE_ENV="production"

bundle config deployment 'true'
bundle config without 'development test exclude'
bundle config set silence_root_warning true
bundle install -j$(getconf _NPROCESSORS_ONLN)

npm install -g corepack
corepack enable

yarn workspaces focus --production @mastodon/mastodon

ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=precompile_placeholder \
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=precompile_placeholder \
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=precompile_placeholder \
OTP_SECRET=precompile_placeholder \
SECRET_KEY_BASE=precompile_placeholder \
bundle exec rails assets:precompile

bundle exec bootsnap precompile --gemfile app/ lib/
cd streaming
yarn workspaces focus --production @mastodon/streaming

yarn cache clean
apk del --purge build-dependencies

npm cache clean --force
apt remove -y git-core g++ gcc autoconf build-essential
apt autoremove -y

rm -rf /var/lib/apt/lists/*
rm -rf /usr/lib/*/perl
rm -rf /usr/lib/*/perl-base
rm -rf /usr/lib/*/dri
rm -rf /usr/lib/*/mfx
rm -rf /usr/lib/*/vdpau
rm -rf /usr/lib/*/gconv
rm -rf /usr/lib/gcc
rm -rf /usr/lib/git-core
rm -rf /tmp

rm -rf node_modules/.cache

cd /mastodon
ln -s /var/snap/mastodon/current/config/.env.production .env.production

cd public
ln -s /var/snap/mastodon/current/system system

cd /mastodon
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' /current/bin/bundle
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' vendor/bundle/ruby/*/bin/*
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' bin/rails
sed -i '1s@^@#!/snap/mastodon/current/ruby/bin/ruby.sh\n@' bin/tootctl
