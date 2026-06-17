# etcd Builder Dockerfile
# Builds etcd from source and outputs binaries

#======================================
# Stage 1: Build etcd
#======================================
FROM golang:1.25-bookworm AS builder

ARG ETCD_VERSION=v3.6.12

RUN apt-get update && apt-get install -y --no-install-recommends \
    git make && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --branch ${ETCD_VERSION} --depth 1 https://github.com/etcd-io/etcd.git .

RUN make build

# Create output directory with binaries and metadata
RUN mkdir -p /etcd/bin && \
    cp /build/bin/etcd /etcd/bin/etcd && \
    cp /build/bin/etcdctl /etcd/bin/etcdctl && \
    cp /build/bin/etcdutl /etcd/bin/etcdutl && \
    chmod +x /etcd/bin/* && \
    echo "etcd ${ETCD_VERSION}" > /etcd/VERSION.txt

#======================================
# Stage 2: Package output (scratch)
#======================================
FROM scratch AS output

ARG ETCD_VERSION=v3.6.12

COPY --from=builder /etcd /etcd
