#!/bin/bash -ex


DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

apt update
apt install -y git imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git-core \
                     g++ libprotobuf-dev protobuf-compiler pkg-config gcc autoconf \
                     bison build-essential libssl-dev libyaml-dev libreadline6-dev \
                     zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
                     libidn11-dev libicu-dev libjemalloc-dev

export PATH=$PATH:$(echo /ruby/rubies/ruby-*/bin)
cd /mastodon

bundle config deployment 'true'
bundle config without 'development test'
bundle install -j$(getconf _NPROCESSORS_ONLN)

apt remove -y git-core g++ gcc autoconf build-essential
apt autoremove -y
rm -rf /var/lib/apt/lists/*
rm -rf /var/lib/apt/lists/*

