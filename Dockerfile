ARG DEBIAN_VERSION="${DEBIAN_VERSION:-stable-slim}"
ARG GO_VERSION="${GO_VERSION:-1.12.13-alpine3.10}"
FROM golang:${GO_VERSION} as dependencies1

WORKDIR /data

#su-exec
ARG SUEXEC_VERSION=v0.2
ARG SUEXEC_HASH=f85e5bde1afef399021fbc2a99c837cf851ceafa

ENV CFLAGS '-fPIC -O2 -g'
ENV CXXFLAGS '-fPIC -O2 -g'
ENV LDFLAGS '-static-libstdc++'

RUN apk add --no-cache --virtual .build-deps \
        ca-certificates \
        g++ \
        g++-multilib \
        make \
        pkg-config \
        doxygen \
        git \
        curl \
        libtool-bin \
        autoconf \
        automake \
        patch \
        bzip2 \
        binutils-gold \
        bsdmainutils \
        python3 \
        musl-dev \
        linux-headers \
        # build-essential \
        libprotobuf-dev protobuf-compiler \
        unzip > /dev/null \
    && cd /data || exit 1 \
    && echo "\e[32mbuilding: su-exec\e[39m" \
    && git clone --branch ${SUEXEC_VERSION} --single-branch --depth 1 https://github.com/ncopa/su-exec.git su-exec.git > /dev/null \
    && cd su-exec.git || exit 1 \
    && test `git rev-parse HEAD` = ${SUEXEC_HASH} || exit 1 \
    && make -j2 > /dev/null \
    && cp su-exec /data \
    && cd /data || exit 1 \
    && rm -rf /data/su-exec.git
# RUN apt-get update -qq && apt-get --no-install-recommends -yqq install \
#         ca-certificates \
#         g++ \
#         g++-multilib \
#         make \
#         pkg-config \
#         doxygen \
#         git \
#         curl \
#         libtool-bin \
#         autoconf \
#         automake \
#         patch \
#         bzip2 \
#         binutils-gold \
#         bsdmainutils \
#         python3 \
#         build-essential \
#         # libtool \
#         libprotobuf-dev protobuf-compiler \
#         unzip > /dev/null \
#     && cd /data || exit 1 \
#     && echo "\e[32mbuilding: su-exec\e[39m" \
#     && git clone --branch ${SUEXEC_VERSION} --single-branch --depth 1 https://github.com/ncopa/su-exec.git su-exec.git > /dev/null \
#     && cd su-exec.git || exit 1 \
#     && test `git rev-parse HEAD` = ${SUEXEC_HASH} || exit 1 \
#     && make -j2 > /dev/null \
#     && cp su-exec /data \
#     && cd /data || exit 1 \
#     && rm -rf /data/su-exec.git

FROM index.docker.io/xmrto/lnd:dependencies1 as builder
WORKDIR /data

ARG PROJECT_URL=github.com/lightningnetwork/lnd
ARG BRANCH=master
ARG BUILD_PATH=/bitcoin.git/build/release/bin

# lnd
RUN go get -d -v ${PROJECT_URL} \
    && cd $GOPATH/src/github.com/lightningnetwork/lnd \
    && git checkout ${BRANCH} \
    && make \
    && make install \
    && ls -l
# 
# 
# 
# https://github.com/lightningnetwork/lnd/releases/download/v0.8.1-beta/lnd-linux-amd64-v0.8.1-beta.tar.gz
# ARG LND_VERSION=v0.8.1-beta
# ARG ARCH=linux-amd64
# ARG LND_ARCHIVE=lnd-${ARCH}-${LND_VERSION}.tar.gz

# RUN cd /data || exit 1 \
#     && wget -q https://github.com/lightningnetwork/lnd/releases/download/${LND_VERSION}/${LND_ARCHIVE} \
#     && wget -q https://github.com/lightningnetwork/lnd/releases/download/${LND_VERSION}/manifest-${LND_VERSION}.txt \
#     && wget -q https://github.com/lightningnetwork/lnd/releases/download/${LND_VERSION}/manifest-${LND_VERSION}.txt.sig \
#     && wget -q https://keybase.io/roasbeef/pgp_keys.asc \
#     && SHA256=`grep "${LND_ARCHIVE}" manifest-${LND_VERSION}.txt | awk '{print $1}'` \
#     && echo $SHA256 \
#     && sha256sum ${LND_ARCHIVE} \
#     && echo "$SHA256 ${LND_ARCHIVE}" | sha256sum -c - \
#     && gpg --import ./pgp_keys.asc \
#     && gpg --verify manifest-${LND_VERSION}.txt.sig \
#     && tar -xzf ${LND_ARCHIVE} \
#     && sudo install -m 0755 -o root -g root -t /usr/local/bin lnd-${ARCH}-${LND_VERSION}/* \
#     && rm -rf /tmp/* \
#     && lnd --version
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# ---
# 
# ENV BASE_DIR /usr/local
# 
# ENV CFLAGS '-fPIC -O2 -g'
# ENV CXXFLAGS '-fPIC -O2 -g'
# ENV LDFLAGS '-static-libstdc++'
# 
# RUN echo "\e[32mcloning: $PROJECT_URL on branch: $BRANCH\e[39m" \
#     && git clone --branch "$BRANCH" --single-branch --recursive $PROJECT_URL bitcoin.git > /dev/null \
#     && cd bitcoin.git || exit 1 \
#     && echo "\e[32mbuilding static binaries\e[39m" \
#     && ldconfig > /dev/null \
#     && ./autogen.sh > /dev/null \
#     && cd depends || exit 1 \
#     && make -j2 HOST=x86_64-pc-linux-gnu NO_QT=1 NO_UPNP=1 > /dev/null \
#     && cd .. || exit 1 \
#     && ./configure --prefix=${PWD}/depends/x86_64-pc-linux-gnu --enable-glibc-back-compat LDFLAGS="$LDFLAGS" --without-miniupnpc --enable-reduce-exports --disable-bench --without-gui > /dev/null \
#     && make -j2 HOST=x86_64-pc-linux-gnu NO_QT=1 NO_UPNP=1 > /dev/null \
#     && echo "\e[32mcopy and clean up\e[39m" \
#     && mv /data/bitcoin.git/src/bitcoind /data/ \
#     && chmod +x /data/bitcoind \
#     && mv /data/bitcoin.git/src/bitcoin-cli /data/ \
#     && chmod +x /data/bitcoin-cli \
#     && cd /data || exit 1 \
#     && rm -rf /data/bitcoin.git \
RUN   apt-get purge -yqq \
          g++ \
          g++-multilib \
          make \
          pkg-config \
          doxygen \
          git \
          curl \
          libtool-bin \
          autoconf \
          automake \
          patch \
          bzip2 \
          binutils-gold \
          bsdmainutils \
          python3 \
          build-essential \
          libprotobuf-dev protobuf-compiler \
          unzip > /dev/null \
      && apt-get autoremove --purge -yqq > /dev/null \
      && apt-get clean > /dev/null \
      && rm -rf /var/tmp/* /tmp/* /var/lib/apt/* > /dev/null
# 

FROM debian:${DEBIAN_VERSION}
COPY --from=builder /go/build/lnd /usr/local/bin/
COPY --from=builder /go/build/lncli /usr/local/bin/
COPY --from=builder /data/su-exec /usr/local/bin/

RUN apt-get autoremove --purge -yqq > /dev/null \
    && apt-get clean > /dev/null \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt > /dev/null

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data

RUN lnd --version > /version.txt \
    && cat /etc/os-release > /system.txt \
    && cat /proc/version >> /system.txt \
    && ldd $(command -v lnd) > /dependencies.txt

VOLUME ["/data","/bitcoin"]

ENV USER_ID=1000
ENV LOG_LEVEL=debug
# ENV DAEMON_HOST 127.0.0.1
# ENV DAEMON_PORT 28081
ENV RPC_BIND=127.0.0.1
ENV RPC_PORT=28081
ENV RPC_USER=""
ENV RPC_PASSWD=""
# ENV RPC_LOGIN ""
ENV ZMQ_PUB_RAW_BLOCK_IP=127.0.0.1
ENV ZMQ_PUB_RAW_BLOCK_PORT=28332
ENV ZMQ_PUB_RAW_BLOCK=""
ENV ZMQ_PUB_RAW_TX_IP=127.0.0.1
ENV ZMQ_PUB_RAW_TX_PORT=28333
ENV ZMQ_PUB_RAW_TX=""

ENTRYPOINT ["/entrypoint.sh"]
