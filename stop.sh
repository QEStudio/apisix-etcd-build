#!/bin/bash

# Stop APISIX + etcd Stack
# Usage: ./stop.sh

set -euo pipefail

echo "Stopping APISIX + etcd stack..."

docker compose down

echo ""
echo "Services stopped."
echo ""
echo "To also remove data volumes:"
echo "  docker compose down -v"
echo ""
