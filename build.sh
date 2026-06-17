#!/bin/bash

# APISIX + etcd Build Script
# Usage: ./build.sh [apisix_version] [etcd_version]
# 
# Default versions:
#   APISIX: 3.16.0
#   etcd:   v3.6.12
#   OpenResty: 1.27.1.2

set -euo pipefail

# Default versions
APISIX_VERSION=${1:-3.16.0}
ETCD_VERSION=${2:-v3.6.12}
OPENRESTY_VERSION=${3:-1.27.1.2}

echo "========================================="
echo " Building APISIX + etcd Docker Images"
echo "========================================="
echo " APISIX Version:     ${APISIX_VERSION}"
echo " etcd Version:       ${ETCD_VERSION}"
echo " OpenResty Version:  ${OPENRESTY_VERSION}"
echo "========================================="

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Error: docker is required but not installed."; exit 1; }

# Build etcd image
echo ""
echo "[1/2] Building etcd image..."
docker build \
    --build-arg ETCD_VERSION=${ETCD_VERSION} \
    -t apisix-etcd:${ETCD_VERSION} \
    -t apisix-etcd:latest \
    -f docker/etcd/Dockerfile \
    docker/etcd

echo "  [OK] etcd image built successfully!"

# Build APISIX image
echo ""
echo "[2/2] Building APISIX image..."
docker build \
    --build-arg APISIX_VERSION=${APISIX_VERSION} \
    --build-arg OPENRESTY_VERSION=${OPENRESTY_VERSION} \
    -t apisix-gateway:${APISIX_VERSION} \
    -t apisix-gateway:latest \
    -f docker/apisix/Dockerfile \
    docker/apisix

echo "  [OK] APISIX image built successfully!"

echo ""
echo "========================================="
echo " Build completed!"
echo "========================================="
echo ""
echo "Images:"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "apisix-(etcd|gateway)"
echo ""
echo "To start services:"
echo "  docker compose up -d"
echo ""
echo "To check status:"
echo "  docker compose ps"
echo ""
echo "To stop services:"
echo "  docker compose down"
echo ""
