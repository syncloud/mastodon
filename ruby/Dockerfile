FROM debian:booksworm-slim
COPY mastodon /mastodon
COPY build-ruby.sh /
COPY build-mastodon.sh /
ARG VERSION
RUN /build-ruby.sh $VERSION
RUN /build-mastodon.sh
