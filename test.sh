#!/bin/bash

# Test APISIX + etcd Stack
# Usage: ./test.sh

set -euo pipefail

echo "========================================="
echo " Testing APISIX + etcd Stack"
echo "========================================="
echo ""

# Test etcd
echo "1. Testing etcd..."
echo ""
echo "   Version:"
docker exec apisix-etcd etcdctl version 2>/dev/null || echo "   [WARN]  etcd not running"
echo ""
echo "   Health:"
docker exec apisix-etcd etcdctl endpoint health 2>/dev/null || echo "   [WARN]  etcd not running"
echo ""

# Test APISIX
echo "2. Testing APISIX..."
echo ""
echo "   Health check:"
HEALTH=$(curl -sf http://127.0.0.1:9090/v1/health 2>/dev/null) && echo "$HEALTH" | python3 -m json.tool 2>/dev/null || echo "   [WARN]  APISIX not running"
echo ""

# Create a test route
echo "3. Creating test route..."
RESPONSE=$(curl -sf http://127.0.0.1:9090/apisix/admin/routes/1 \
    -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' \
    -X PUT -d '{
        "uri": "/test",
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "httpbin.org:80": 1
            }
        }
    }' 2>/dev/null) && echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "   [WARN]  Failed to create route"
echo ""

# Test the route
echo "4. Testing route..."
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9080/test 2>/dev/null || echo "failed")
if [ "$HTTP_CODE" != "failed" ]; then
    echo "   HTTP Status: $HTTP_CODE"
else
    echo "   [WARN]  Route test failed"
fi
echo ""

echo ""
echo "========================================="
if [ "$HTTP_CODE" != "failed" ]; then
    echo " [OK] All tests completed!"
else
    echo " [WARN]  Some tests failed - check logs with: docker compose logs"
fi
echo "========================================="
echo ""
