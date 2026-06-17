#!/bin/bash
# Start APISIX
# Usage: ./apisix/start.sh

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APISIX_HOME="$(cd "$DIR/.." && pwd)"

# Source environment from set-env.sh (generated during packaging)
if [ -f "$APISIX_HOME/set-env.sh" ]; then
    source "$APISIX_HOME/set-env.sh"
fi

export PATH="$APISIX_HOME/openresty/bin:$APISIX_HOME/openresty/nginx/sbin:$PATH"
export LD_LIBRARY_PATH="$APISIX_HOME/lib:$APISIX_HOME/openresty/luajit/lib:$APISIX_HOME/openresty/lib:${LD_LIBRARY_PATH:-}"
export LUA_PATH="$APISIX_HOME/apisix/deps/share/lua/5.1/?.lua;$APISIX_HOME/apisix/deps/share/lua/5.1/?/init.lua;$APISIX_HOME/apisix/?.lua;$APISIX_HOME/apisix/?/init.lua;"
export LUA_CPATH="$APISIX_HOME/apisix/deps/lib/lua/5.1/?.so;"

PID_FILE="$APISIX_HOME/apisix/logs/nginx.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "APISIX is already running (PID $(cat "$PID_FILE"))"
    exit 0
fi

echo "Starting APISIX..."
cd "$APISIX_HOME/apisix"
if ! bin/apisix start 2>/dev/null; then
    echo "[FAIL] APISIX failed to start"
    tail -30 "$APISIX_HOME/apisix/logs/error.log" 2>/dev/null || true
    exit 1
fi

# Wait for Admin API
for i in $(seq 15); do
    if curl -sf http://127.0.0.1:9090/v1/health >/dev/null 2>&1; then
        echo "[OK] APISIX ready"
        exit 0
    fi
    sleep 2
done

echo "[WARN] APISIX started but Admin API not responding"
tail -20 "$APISIX_HOME/apisix/logs/error.log" 2>/dev/null || true
exit 1
