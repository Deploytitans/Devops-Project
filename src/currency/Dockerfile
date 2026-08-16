# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0
# Copyright 2023 The OpenTelemetry Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM alpine:3.20 AS builder

RUN apk add --no-cache git cmake make g++ grpc-dev protobuf-dev linux-headers

ARG OPENTELEMETRY_CPP_VERSION

RUN git clone --depth 1 --branch v${OPENTELEMETRY_CPP_VERSION} https://github.com/open-telemetry/opentelemetry-cpp \
    && cd opentelemetry-cpp/ \
    && mkdir build \
    && cd build \
    && cmake .. -DCMAKE_CXX_STANDARD=17 -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
          -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
          -DWITH_EXAMPLES=OFF -DWITH_OTLP_GRPC=ON -DWITH_ABSEIL=ON \
    && make -j$(nproc || sysctl -n hw.ncpu || echo 1) install && cd ../..

COPY ./src/currency /currency
COPY ./pb/demo.proto /currency/proto/demo.proto

RUN cd /currency \
    && mkdir -p build && cd build \
    && cmake .. -DCMAKE_POLICY_DEFAULT_CMP0057=NEW \
    && make -j$(nproc || sysctl -n hw.ncpu || echo 1) install


FROM alpine:3.20 AS release

RUN apk add --no-cache grpc-dev protobuf-dev \
    && addgroup -S app && adduser -S -G app -u 10001 app
COPY --from=builder /usr/local /usr/local

USER 10001:10001
EXPOSE ${CURRENCY_PORT}
ENTRYPOINT ["sh", "-c", "exec /usr/local/bin/currency ${CURRENCY_PORT}"]
