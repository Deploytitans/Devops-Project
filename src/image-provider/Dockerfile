# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

FROM nginx:1.31.3-otel@sha256:3067aa878ab982e384505c4a9f51392316c088758a55370ee067b465bcbe2794

RUN mkdir /static
COPY src/image-provider/static /static

EXPOSE ${IMAGE_PROVIDER_PORT}

STOPSIGNAL SIGQUIT

COPY src/image-provider/nginx.conf.template /nginx.conf.template

USER nginx
CMD ["/bin/sh" , "-c" , "envsubst '$OTEL_COLLECTOR_HOST $IMAGE_PROVIDER_PORT $OTEL_COLLECTOR_PORT_GRPC $OTEL_SERVICE_NAME' < /nginx.conf.template > /tmp/nginx.conf && exec nginx -c /tmp/nginx.conf -g 'daemon off;'"]
