#!/bin/bash
# Stop both etcd and APISIX

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo " Stopping APISIX + etcd"
echo "========================================"
echo ""

# Stop APISIX first (graceful shutdown)
echo "[1/2] Stopping APISIX..."
"$DIR/apisix/stop.sh"
echo ""

# Stop etcd
echo "[2/2] Stopping etcd..."
"$DIR/etcd/stop.sh"
echo ""
echo "[OK] All services stopped"
