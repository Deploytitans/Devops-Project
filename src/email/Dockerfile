# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0


FROM ruby:3.4-slim-bookworm@sha256:514336e7d46dd52b94a7391e4bc34dc04dc83098963c2c2493b90354952acd78 AS base

FROM base AS builder

WORKDIR /tmp

COPY ./src/email/Gemfile ./src/email/Gemfile.lock ./

#RUN apk update && apk add make gcc musl-dev gcompat && bundle install
RUN apt-get update \
    && apt-get install --no-install-recommends -y build-essential \
    && bundle config set without development:test \
    && bundle install --jobs 4 --retry 3 \
    && rm -rf /var/lib/apt/lists/* /root/.bundle/cache
FROM base AS release

WORKDIR /email_server
RUN apt-get update \
    && apt-get upgrade --yes --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app app

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --chown=app:app ./src/email/ .

USER 10001:10001
EXPOSE ${EMAIL_PORT}
ENTRYPOINT ["bundle", "exec", "ruby", "email_server.rb"]
