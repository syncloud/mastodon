ARG VERSION
FROM ruby:$VERSION
COPY mastodon /
WORKDIR /mastodon
RUN apt update
RUN apt install -y git imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git-core \
                         g++ libprotobuf-dev protobuf-compiler pkg-config gcc autoconf \
                         bison build-essential libssl-dev libyaml-dev libreadline6-dev \
                         zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
                         libidn11-dev libicu-dev libjemalloc-dev
RUN bundle config deployment 'true'
RUN bundle config without 'development test'
RUN bundle install -j$(getconf _NPROCESSORS_ONLN)

RUN apt remove -y git-core g++ gcc autoconf build-essential
RUN apt autoremove -y
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/lib/apt/lists/*
