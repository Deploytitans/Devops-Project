# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

FROM golang:1.25.7-alpine AS gosu-builder
RUN apk add --no-cache git \
    && git clone --depth 1 --branch 1.19 https://github.com/tianon/gosu.git /src/gosu \
    && cd /src/gosu \
    && CGO_ENABLED=0 go build -trimpath -o /gosu .

FROM postgres:17.11-alpine3.24@sha256:5d61573b31c206ae538c85893edeb6e320e1a9ffd838c0f9dca927fb6f765fa4

COPY --from=gosu-builder /gosu /usr/local/bin/gosu
COPY ./src/postgres/init.sql /docker-entrypoint-initdb.d/init.sql

USER postgres
EXPOSE ${POSTGRES_PORT}
