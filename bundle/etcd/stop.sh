#!/bin/bash
# Stop etcd server

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$DIR/etcd.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "etcd is not running (no PID file)"
    exit 0
fi

PID=$(cat "$PID_FILE")
if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping etcd (PID $PID)..."
    kill "$PID" 2>/dev/null || true
    for i in $(seq 5); do
        if ! kill -0 "$PID" 2>/dev/null; then
            echo "[OK] etcd stopped"
            rm -f "$PID_FILE"
            exit 0
        fi
        sleep 1
    done
    echo "Force killing etcd..."
    kill -9 "$PID" 2>/dev/null || true
else
    echo "etcd not running (stale PID)"
fi
rm -f "$PID_FILE"
