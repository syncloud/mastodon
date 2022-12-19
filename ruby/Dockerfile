ARG VERSION
FROM ruby:$VERSION
COPY mastodon /
WORKDIR /mastodon
RUN bundle config deployment 'true'
RUN bundle config without 'development test'
RUN bundle install -j$(getconf _NPROCESSORS_ONLN)
RUN yarn install --pure-lockfile
RUN rm -rf /var/lib/apt/lists/*
