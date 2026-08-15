FROM golang:1.22-alpine3.20 AS builder

WORKDIR /usr/src/app/

# Use Go build cache for dependencies
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    mkdir -p /root/.cache/go-build

COPY ./src/product-catalog/go.mod ./src/product-catalog/go.sum ./

# Download
RUN go mod download

# Copy the rest of the source code
COPY ./src/product-catalog/ .

RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o product-catalog .

####################################

FROM alpine:3.20 AS release

WORKDIR /usr/src/app/
RUN addgroup -S app && adduser -S -G app -u 10001 app

COPY --chown=app:app ./src/product-catalog/products/ ./products/
COPY --chown=app:app --from=builder /usr/src/app/product-catalog ./product-catalog

ENV PRODUCT_CATALOG_PORT=8088
USER 10001:10001
ENTRYPOINT [ "./product-catalog" ]
