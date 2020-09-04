ARG GO_VERSION="${GO_VERSION:-1.13.12-alpine3.12}"
FROM golang:${GO_VERSION} as dependencies1

WORKDIR /data

#su-exec
ARG SUEXEC_VERSION=v0.2
ARG SUEXEC_HASH=f85e5bde1afef399021fbc2a99c837cf851ceafa

ENV CFLAGS '-fPIC -O2 -g'
ENV CXXFLAGS '-fPIC -O2 -g'
ENV LDFLAGS '-static-libstdc++'

RUN apk add --virtual .build-deps \
        g++ \
        make \
        autoconf \
        automake \
        musl-dev \
        linux-headers \
        build-base \
    && apk add --no-cache \
        ca-certificates \
        git \
        curl \
        python3 \
    && cd /data || exit 1 \
    && echo "\e[32mbuilding: su-exec\e[39m" \
    && git clone --branch ${SUEXEC_VERSION} --single-branch --depth 1 https://github.com/ncopa/su-exec.git su-exec.git > /dev/null \
    && cd su-exec.git || exit 1 \
    && test `git rev-parse HEAD` = ${SUEXEC_HASH} || exit 1 \
    && make -j2 > /dev/null \
    && cp su-exec /data \
    && cd /data || exit 1 \
    && rm -rf /data/su-exec.git


FROM index.docker.io/xmrto/lnd:dependencies1 as builder
WORKDIR /data

ARG PROJECT_URL=github.com/lightningnetwork/lnd
ARG BRANCH=master
ARG BUILD_BRANCH=$BRANCH

# lnd
RUN go get -d -v ${PROJECT_URL} \
    && cd $GOPATH/src/github.com/lightningnetwork/lnd \
    # && git checkout ${BRANCH} \
    && git checkout "$BUILD_BRANCH" \
    && git submodule update --init --force \
    && make \
    && make install \
    && apk del .build-deps

FROM golang:${GO_VERSION}
COPY --from=builder /data/su-exec /usr/local/bin/
COPY --from=builder /go/bin/lnd /usr/local/bin/
COPY --from=builder /go/bin/lncli /usr/local/bin/

RUN apk add --no-cache \
        bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data

RUN lnd --version > /version.txt \
    && cat /etc/os-release > /system.txt \
    && cat /proc/version >> /system.txt \
    && ldd $(command -v lnd) > /dependencies.txt

VOLUME ["/data"]

ENV USER_ID=1000
ENV LOG_LEVEL=debug
ENV RPC_HOST=127.0.0.1
ENV RPC_PORT=28081
ENV RPC_USER=""
ENV RPC_PASSWD=""
ENV ZMQ_PUB_RAW_BLOCK_IP=127.0.0.1
ENV ZMQ_PUB_RAW_BLOCK_PORT=28332
ENV ZMQ_PUB_RAW_BLOCK=""
ENV ZMQ_PUB_RAW_TX_IP=127.0.0.1
ENV ZMQ_PUB_RAW_TX_PORT=28333
ENV ZMQ_PUB_RAW_TX=""

ENTRYPOINT ["/entrypoint.sh"]
