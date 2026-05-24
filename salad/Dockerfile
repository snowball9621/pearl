FROM nvidia/cuda:12.9.1-runtime-ubuntu24.04

ARG ALPHA_MINER_URL=https://github.com/AlphaMine-Tech/alpha-miner/releases/latest/download/alpha-miner

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl python3 procps \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fL --retry 3 -o /usr/local/bin/alpha-miner "${ALPHA_MINER_URL}" \
  && chmod 0755 /usr/local/bin/alpha-miner

COPY salad/entrypoint.sh /usr/local/bin/pearl-salad-entrypoint
RUN chmod 0755 /usr/local/bin/pearl-salad-entrypoint \
  && mkdir -p /var/log/pearl /var/run/pearl

ENV WALLET=prl1pvgs56cfqzkfzqjgm6npgw3j5jc3w8ra2uk6ysdum58qpzmnanzmsfs4kjz \
    POOL_HOST=eu1.alphapool.tech \
    POOL_PORT=5566 \
    DIFF=524288 \
    STATUS_INTERVAL=30 \
    MONITOR_URL=http://203.55.176.251:8080/api/heartbeat

ENTRYPOINT ["/usr/local/bin/pearl-salad-entrypoint"]
