ARG NODE
FROM node:$NODE
COPY mastodon /mastodon
COPY build-ruby.sh /
ARG RUBY
RUN /build-ruby.sh $RUBY
