#!/bin/bash
# Stop APISIX

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APISIX_HOME="$(cd "$DIR/.." && pwd)"

export PATH="$APISIX_HOME/openresty/bin:$APISIX_HOME/openresty/nginx/sbin:$PATH"
export LD_LIBRARY_PATH="$APISIX_HOME/lib:$APISIX_HOME/openresty/luajit/lib:$APISIX_HOME/openresty/lib:${LD_LIBRARY_PATH:-}"

PID_FILE="$APISIX_HOME/apisix/logs/nginx.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "APISIX is not running (no PID file)"
    exit 0
fi

PID=$(cat "$PID_FILE")
echo "Stopping APISIX (PID $PID)..."
cd "$APISIX_HOME/apisix"
bin/apisix stop 2>/dev/null || true

# Wait for process to exit
for i in $(seq 5); do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "[OK] APISIX stopped"
        exit 0
    fi
    sleep 1
done

# Force kill if needed
kill -9 "$PID" 2>/dev/null || true
rm -f "$PID_FILE"
echo "[OK] APISIX stopped (forced)"
