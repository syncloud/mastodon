ARG VERSION
FROM debian:buster-slim
COPY mastodon /mastodon
COPY build-ruby.sh /
COPY build-mastodon.sh /
RUN /build-ruby.sh $VERSION
RUN /build-mastodon.sh
