#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

SOLR_PORT=${SOLR_PORT:-8983}
CORE_NAME="${CUSTOMER_NAME}_core"

echo "=========================================="
echo "Create Solr Core"
echo "=========================================="

# Wait for Solr to be ready
echo "Waiting for Solr to be ready..."
for i in {1..30}; do
    if curl -sf "http://localhost:$SOLR_PORT/solr/admin/ping?wt=json" > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Check if core already exists
if curl -sf -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    "http://localhost:$SOLR_PORT/solr/admin/cores?action=STATUS&core=$CORE_NAME&wt=json" | \
    grep -q "\"$CORE_NAME\""; then
    echo "Core '$CORE_NAME' already exists"
    exit 0
fi

echo "Creating core: $CORE_NAME"

# Create core using Moodle schema
curl -sf -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    "http://localhost:$SOLR_PORT/solr/admin/cores?action=CREATE&name=$CORE_NAME&configSet=_default&wt=json"

echo ""
echo "Uploading Moodle schema..."

# Upload schema
curl -sf -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    -X POST \
    -H 'Content-type:application/xml' \
    --data-binary @"$PROJECT_DIR/config/moodle_schema.xml" \
    "http://localhost:$SOLR_PORT/solr/$CORE_NAME/schema"

echo ""
echo "✓ Core created successfully"
echo "Core name: $CORE_NAME"
echo "Core URL: http://localhost:$SOLR_PORT/solr/$CORE_NAME"
echo "=========================================="
