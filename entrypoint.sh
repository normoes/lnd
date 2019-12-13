#!/bin/bash

# allow 3 files with 5MB each
LOGGING="--debuglevel=$LOG_LEVEL --maxlogfilesize=5242880 --maxlogfiles=3"

# please set all or none of bitcoind.rpcuser, bitcoind.rpcpass, bitcoind.zmqpubrawblock, bitcoind.zmqpubrawtx

# rpc login options
if [ -n "$RPC_USER" -a -n "$RPC_PASSWD" -a -n "$RPC_HOST" ]; then
    RPC_LOGIN="--bitcoind.rpcuser=$RPC_USER --bitcoind.rpcpass=$RPC_PASSWD  --bitcoind.rpchost=$RPC_HOST"
fi

# zeromq options
if [ -n "$ZMQ_PUB_RAW_BLOCK_IP" -a -n "$ZMQ_PUB_RAW_BLOCK_PORT" ]; then
    ZMQ_PUB_RAW_BLOCK="--bitcoind.zmqpubrawblock=tcp://$ZMQ_PUB_RAW_BLOCK_IP:$ZMQ_PUB_RAW_BLOCK_PORT"
fi
if [ -n "$ZMQ_PUB_RAW_TX_IP" -a -n "$ZMQ_PUB_RAW_TX_PORT" ]; then
    ZMQ_PUB_RAW_TX="--bitcoind.zmqpubrawtx=tcp://$ZMQ_PUB_RAW_TX_IP:$ZMQ_PUB_RAW_TX_PORT"
fi

OPTIONS="--bitcoin.active $LOGGING --bitcoin.node=bitcoind $RPC_LOGIN $ZMQ_PUB_RAW_BLOCK $ZMQ_PUB_RAW_TX --listen=0.0.0.0 externalip=0.0.0.0"

SERVICE="lnd $@ $OPTIONS"

## lnd
if [[ "${1:0:1}" = '-' ]]  || [[ -z "$@" ]]; then
  set -- $SERVICE
## lncli
elif [[ "$1" = lncli* ]]; then
  set -- "$@"
fi

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # USER_ID defaults to 1000 (Dockerfile)
  adduser --system --group --uid "$USER_ID" --shell /bin/false lnd &> /dev/null
  exec su-exec lnd $@
fi

exec $@
