ARG NODE
FROM node:$NODE
COPY mastodon /mastodon
COPY build-ruby.sh /
COPY build-mastodon.sh /
ARG RUBY
RUN /build-ruby.sh $RUBY
RUN /build-mastodon.sh
