#!/bin/bash
# Start both etcd and APISIX
# Usage: ./start.sh [etcd-data-dir]

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${1:-$DIR/etcd/data}"

echo "========================================"
echo " Starting APISIX + etcd"
echo "========================================"
echo ""

# Start etcd first
echo "[1/2] Starting etcd..."
if "$DIR/etcd/start.sh" "$DATA_DIR"; then
    echo ""
else
    echo "[WARN] etcd may not be ready yet, continuing..."
    echo ""
fi

# Start APISIX
echo "[2/2] Starting APISIX..."
"$DIR/apisix/start.sh"

echo ""
echo "[OK] APISIX + etcd stack started"
echo ""
echo "Endpoints:"
echo "  APISIX HTTP:   http://127.0.0.1:9080"
echo "  APISIX Admin:  http://127.0.0.1:9090"
echo "  etcd Client:   http://127.0.0.1:2379"
echo ""
echo "Use ./stop.sh to stop all services."
