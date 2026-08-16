# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

FROM postgres:17.11-alpine3.24@sha256:5d61573b31c206ae538c85893edeb6e320e1a9ffd838c0f9dca927fb6f765fa4

COPY ./src/postgres/init.sql /docker-entrypoint-initdb.d/init.sql

USER postgres
EXPOSE ${POSTGRES_PORT}
