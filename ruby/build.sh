#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1

BUILD_DIR=${DIR}/../build/snap/ruby
mkdir -p ${BUILD_DIR}

cd ${DIR}/../build
${DIR}/../download-retry.sh https://github.com/mastodon/mastodon/archive/refs/tags/v${VERSION}.tar.gz v${VERSION}.tar.gz
tar xf v${VERSION}.tar.gz
cd mastodon-${VERSION}

${DIR}/../apk.sh \
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
gdbm-dev \
gmp-dev \
openssl-dev \
shared-mime-info \
npm \
vips-dev \
git \
file \
imagemagick \
ffmpeg \
ffplay

export RAILS_ENV=production
export NODE_ENV=production
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

BUNDLER_VERSION=$(awk '/^BUNDLED WITH$/{getline; gsub(/ /,""); print; exit}' Gemfile.lock)
test -n "${BUNDLER_VERSION}"
gem install bundler -v "${BUNDLER_VERSION}" --no-document
bundle --version | grep -q "${BUNDLER_VERSION}"

PRISM_VERSION=$(awk '/^    prism \(/{gsub(/[^0-9.]/,""); print; exit}' Gemfile.lock)
test -n "${PRISM_VERSION}"
gem install prism -v "${PRISM_VERSION}" --no-document
RUBY_LIB_DIR=$(ruby -e 'puts RbConfig::CONFIG["rubylibdir"]')
RUBY_ARCH_DIR=$(ruby -e 'puts RbConfig::CONFIG["rubyarchdir"]')
rm -rf "${RUBY_LIB_DIR}/prism.rb" "${RUBY_LIB_DIR}/prism" "${RUBY_ARCH_DIR}/prism.so"
ruby -e 'require "prism"; raise "stale prism #{Prism::VERSION}" unless defined?(Prism::CurrentVersionError)'

bundle config deployment 'true'
bundle config without 'development test'
bundle config set silence_root_warning true
bundle install -j$(getconf _NPROCESSORS_ONLN)

rm -f /usr/bin/yarn /usr/bin/yarnpkg
npm install -g corepack
corepack enable

yarn workspaces focus --production --all

SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

test -d public/assets
test -d public/packs
for dep in express ioredis pg ws; do
  test -d node_modules/$dep || test -d streaming/node_modules/$dep
done

apk del \
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
