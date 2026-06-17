#!/bin/bash

# Start APISIX + etcd Stack
# Usage: ./start.sh

set -euo pipefail

echo "Starting APISIX + etcd stack..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Create network if not exists
docker network create apisix-network 2>/dev/null || true

# Start services
docker compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 10

# Check etcd health
echo ""
echo "Checking etcd health..."
docker exec apisix-etcd etcdctl endpoint health || echo "Warning: etcd health check failed"

# Check APISIX health
echo ""
echo "Checking APISIX health..."
sleep 5
curl -sf http://127.0.0.1:9090/v1/health || echo "Warning: APISIX health check failed"

echo ""
echo "========================================="
echo " Services started successfully!"
echo "========================================="
echo ""
echo "Endpoints:"
echo "  APISIX HTTP:     http://localhost:9080"
echo "  APISIX HTTPS:    https://localhost:9443"
echo "  APISIX Admin:    http://localhost:9090"
echo "  etcd Client:     http://localhost:2379"
echo ""
echo "Admin API Key: edd1c9f034335f136f87ad84b625c8f1"
echo ""
echo "Useful commands:"
echo "  View logs:     docker compose logs -f"
echo "  Stop services: docker compose down"
echo "  Check status:  docker compose ps"
echo ""
