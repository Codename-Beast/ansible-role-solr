#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo "Error: .env file not found. Copy .env.example to .env and configure it."
    exit 1
fi

# Function to hash password using Python
hash_password() {
    python3 "$SCRIPT_DIR/hash-password.py" "$1"
}

# Generate password hashes
echo "Generating password hashes..."
ADMIN_HASH=$(hash_password "$SOLR_ADMIN_PASSWORD")
SUPPORT_HASH=$(hash_password "$SOLR_SUPPORT_PASSWORD")
CUSTOMER_HASH=$(hash_password "$SOLR_CUSTOMER_PASSWORD")

# Generate core name from customer name or domain
CORE_NAME=$(echo "${CUSTOMER_NAME}_core" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]/_/g')

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Generate security.json
cat > "$CONFIG_DIR/security.json" <<EOF
{
  "authentication": {
    "blockUnknown": true,
    "class": "solr.BasicAuthPlugin",
    "credentials": {
      "${SOLR_ADMIN_USER}": "${ADMIN_HASH}",
      "${SOLR_SUPPORT_USER}": "${SUPPORT_HASH}",
      "${SOLR_CUSTOMER_USER}": "${CUSTOMER_HASH}"
    },
    "realm": "Solr Authentication",
    "forwardCredentials": false
  },
  "authorization": {
    "class": "solr.RuleBasedAuthorizationPlugin",
    "permissions": [
      { "name": "health-check-ping", "path": "/admin/ping", "role": null },
      { "name": "health-check-detailed", "path": "/admin/health", "role": null },
      { "name": "health-check-simple", "path": "/admin/healthcheck", "role": null },
      { "name": "security-read", "role": "admin" },
      { "name": "security-edit", "role": "admin" },
      { "name": "schema-edit", "role": "admin" },
      { "name": "config-edit", "role": "admin" },
      { "name": "collection-admin-edit", "role": "admin" },
      { "name": "core-admin-read", "role": "admin" },
      { "name": "core-admin-edit", "role": "admin" },
      { "name": "delete", "collection": "${CORE_NAME}", "role": ["admin"] },
      { "name": "metrics", "path": "/admin/metrics", "role": ["admin", "support"] },
      { "name": "backup", "path": "/admin/cores", "role": ["admin"] },
      { "name": "logging", "path": "/admin/logging", "role": ["admin", "support"] },
      { "name": "read", "collection": "${CORE_NAME}", "role": ["admin", "support", "customer"] },
      { "name": "update", "collection": "${CORE_NAME}", "role": ["admin", "customer"] }
    ],
    "user-role": {
      "${SOLR_ADMIN_USER}": ["admin"],
      "${SOLR_SUPPORT_USER}": ["support"],
      "${SOLR_CUSTOMER_USER}": ["customer"]
    }
  }
}
EOF

echo "✓ Generated: config/security.json"

# Language files are already in lang/ directory - no need to copy

echo "✓ Generated: stopwords files"

# Generate empty synonyms and protwords if they don't exist
touch "$CONFIG_DIR/synonyms.txt"
touch "$CONFIG_DIR/protwords.txt"

echo ""
echo "========================================  "
echo "Configuration files generated successfully"
echo "========================================"
echo "Core name: $CORE_NAME"
echo "Config directory: $CONFIG_DIR"
echo ""
echo "Next steps:"
echo "  1. Review config/security.json"
echo "  2. Run: make start"
echo "========================================  "
