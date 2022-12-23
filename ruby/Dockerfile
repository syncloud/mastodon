FROM debian:bookworm-slim
COPY mastodon /mastodon
COPY build-ruby.sh /
COPY build-mastodon.sh /
ARG VERSION
RUN /build-ruby.sh $VERSION
RUN /build-mastodon.sh

