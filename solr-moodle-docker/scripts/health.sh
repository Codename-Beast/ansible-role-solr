#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

SOLR_PORT=${SOLR_PORT:-8983}
SOLR_HOST="localhost:$SOLR_PORT"

echo "=========================================="
echo "Solr Health Check"
echo "=========================================="

# Check if container is running
if ! docker compose ps | grep -q "Up"; then
    echo "✗ Solr container is not running"
    exit 1
fi

echo "✓ Container is running"

# Check ping endpoint
if curl -sf "http://$SOLR_HOST/solr/admin/ping?wt=json" > /dev/null; then
    echo "✓ Ping endpoint responding"
else
    echo "✗ Ping endpoint not responding"
    exit 1
fi

# Check system info (requires auth)
if [ -n "$SOLR_ADMIN_USER" ] && [ -n "$SOLR_ADMIN_PASSWORD" ]; then
    if curl -sf -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
        "http://$SOLR_HOST/solr/admin/info/system?wt=json" > /dev/null; then
        echo "✓ System API responding"
    else
        echo "✗ System API not responding (check credentials)"
    fi
fi

# Get detailed health
echo ""
echo "Detailed Health:"
curl -s "http://$SOLR_HOST/solr/admin/health?wt=json" | python3 -m json.tool 2>/dev/null || echo "No detailed health available"

echo ""
echo "=========================================="
echo "Health check completed successfully"
echo "=========================================="
