#!/bin/bash
# Restart both etcd and APISIX
# Usage: ./restart.sh [etcd-data-dir]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${1:-$DIR/etcd/data}"

echo "Restarting APISIX + etcd stack..."

"$DIR/stop.sh"
echo ""
echo "--- Waiting 3s ---"
sleep 3
echo ""
"$DIR/start.sh" "$DATA_DIR"
