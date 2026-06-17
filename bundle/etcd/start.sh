#!/bin/bash
# Start etcd server
# Usage: ./etcd/start.sh [data-dir]

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${1:-$DIR/data}"
PID_FILE="$DIR/etcd.pid"

mkdir -p "$DATA_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "etcd is already running (PID $(cat "$PID_FILE"))"
    exit 0
fi

echo "Starting etcd..."
"$DIR/bin/etcd" \
    --data-dir="$DATA_DIR" \
    --listen-client-urls=http://127.0.0.1:2379 \
    --advertise-client-urls=http://127.0.0.1:2379 \
    --listen-peer-urls=http://127.0.0.1:2380 \
    --initial-advertise-peer-urls=http://127.0.0.1:2380 \
    --initial-cluster=default=http://127.0.0.1:2380 \
    > "$DIR/etcd.log" 2>&1 &
ETCD_PID=$!
echo $ETCD_PID > "$PID_FILE"

# Wait for etcd to become healthy
for i in $(seq 10); do
    if "$DIR/bin/etcdctl" endpoint health 2>/dev/null | grep -q "healthy"; then
        echo "[OK] etcd ready (PID $ETCD_PID)"
        exit 0
    fi
    sleep 1
done

echo "[WARN] etcd started but health check timed out (PID $ETCD_PID)"
exit 1
