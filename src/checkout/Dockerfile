# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0


FROM golang:1.22-alpine AS builder

WORKDIR /usr/src/app/

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,source=./src/checkout/go.sum,target=go.sum \
    --mount=type=bind,source=./src/checkout/go.mod,target=go.mod \
    go mod download

RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=bind,rw,source=./src/checkout,target=. \
    go build -ldflags "-s -w" -o /go/bin/checkout/ ./

FROM alpine:3.20

WORKDIR /usr/src/app/
RUN addgroup -S app && adduser -S -G app -u 10001 app

COPY --chown=app:app --from=builder /go/bin/checkout/ ./

USER 10001:10001
EXPOSE ${CHECKOUT_PORT}
ENTRYPOINT [ "./checkout" ]
