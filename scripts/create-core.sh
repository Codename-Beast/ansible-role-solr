#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

# Allow CONFIG_DIR to be overridden (v3.4.1)
CONFIG_DIR="${SOLR_CONFIG_DIR:-$PROJECT_DIR/config}"

SOLR_PORT=${SOLR_PORT:-8983}
CORE_NAME="${CUSTOMER_NAME}_core"

echo "=========================================="
echo "Create Solr Core"
echo "=========================================="

# Wait for Solr to be ready
echo "Waiting for Solr to be ready..."
for i in {1..30}; do
    if curl -sf "http://localhost:$SOLR_PORT/" > /dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Check if core already exists AND is functional
CORE_STATUS=$(curl -sf -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    "http://localhost:$SOLR_PORT/solr/admin/cores?action=STATUS&core=$CORE_NAME&wt=json")

if echo "$CORE_STATUS" | grep -q "\"instanceDir\""; then
    echo "Core '$CORE_NAME' already exists and is functional"
    exit 0
fi

# If core is registered but empty (broken), unload it first
if echo "$CORE_STATUS" | grep -q "\"$CORE_NAME\""; then
    echo "Removing broken core registration..."
    curl -sf -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
        "http://localhost:$SOLR_PORT/solr/admin/cores?action=UNLOAD&core=$CORE_NAME&deleteInstanceDir=true&wt=json" > /dev/null || true
fi

echo "Creating core: $CORE_NAME"

# Create core using Moodle schema
CREATE_RESPONSE=$(curl -s -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    "http://localhost:$SOLR_PORT/solr/admin/cores?action=CREATE&name=$CORE_NAME&configSet=_default&wt=json")

if echo "$CREATE_RESPONSE" | grep -q "\"status\":0"; then
    echo "✓ Core created successfully"
else
    echo "ERROR: Failed to create core"
    echo "$CREATE_RESPONSE"
    exit 1
fi

echo ""
echo "Uploading Moodle schema..."

# Upload schema
SCHEMA_RESPONSE=$(curl -s -u "$SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD" \
    -X POST \
    -H 'Content-type:application/xml' \
    --data-binary @"$CONFIG_DIR/moodle_schema.xml" \
    "http://localhost:$SOLR_PORT/solr/$CORE_NAME/schema")

if echo "$SCHEMA_RESPONSE" | grep -q "\"status\":0"; then
    echo "✓ Schema uploaded successfully"
else
    echo "ERROR: Failed to upload schema"
    echo "$SCHEMA_RESPONSE"
    exit 1
fi

echo ""
echo "✓ Core created successfully"
echo "Core name: $CORE_NAME"
echo "Core URL: http://localhost:$SOLR_PORT/solr/$CORE_NAME"
echo "=========================================="
