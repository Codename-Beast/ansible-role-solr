#!/bin/bash
set -e

# Eledia Solr Entrypoint Script
# Version: 2.0.0
# Handles initialization, config generation, and Solr startup

echo "========================================"
echo "Eledia Solr 9.9.0 - Standalone Edition"
echo "Version: 2.0.0"
echo "========================================"

# ============================================================
# ENVIRONMENT VARIABLE VALIDATION
# ============================================================

# Required variables
: "${SOLR_AUTH_ENABLED:=true}"
: "${SOLR_USE_MOODLE_SCHEMA:=false}"
: "${SOLR_CORE_NAME:=moodle}"
: "${CUSTOMER_NAME:=default}"

# Auth variables (optional - will be generated if not provided)
: "${SOLR_ADMIN_USER:=admin}"
: "${SOLR_SUPPORT_USER:=support}"
: "${SOLR_CUSTOMER_USER:=customer}"

# Optional variables with defaults
: "${SOLR_HEAP:=512m}"
: "${SOLR_JAVA_MEM:=-Xms512m -Xmx512m}"
: "${SOLR_LOG_LEVEL:=INFO}"

echo "[INFO] Configuration:"
echo "  - Auth enabled: ${SOLR_AUTH_ENABLED}"
echo "  - Moodle schema: ${SOLR_USE_MOODLE_SCHEMA}"
echo "  - Core name: ${SOLR_CORE_NAME}"
echo "  - Customer: ${CUSTOMER_NAME}"
echo "  - Heap size: ${SOLR_HEAP}"

# ============================================================
# PASSWORD GENERATION / VALIDATION
# ============================================================

generate_password() {
    # Generate secure random password (24 characters)
    tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 24
}

if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
    echo ""
    echo "[1/7] Password Management..."

    # Generate passwords if not provided
    if [ -z "${SOLR_ADMIN_PASSWORD}" ]; then
        export SOLR_ADMIN_PASSWORD=$(generate_password)
        echo "  [GENERATED] Admin password: ${SOLR_ADMIN_PASSWORD}"
    else
        echo "  [PROVIDED] Admin password: ********"
    fi

    if [ -z "${SOLR_SUPPORT_PASSWORD}" ]; then
        export SOLR_SUPPORT_PASSWORD=$(generate_password)
        echo "  [GENERATED] Support password: ${SOLR_SUPPORT_PASSWORD}"
    else
        echo "  [PROVIDED] Support password: ********"
    fi

    if [ -z "${SOLR_CUSTOMER_PASSWORD}" ]; then
        export SOLR_CUSTOMER_PASSWORD=$(generate_password)
        echo "  [GENERATED] Customer password: ${SOLR_CUSTOMER_PASSWORD}"
    else
        echo "  [PROVIDED] Customer password: ********"
    fi

    # Hash passwords using Python script
    echo "  [HASHING] Generating SHA256 password hashes..."
    export SOLR_ADMIN_PASSWORD_HASH=$(python3 /opt/eledia/scripts/hash-password.py "${SOLR_ADMIN_PASSWORD}")
    export SOLR_SUPPORT_PASSWORD_HASH=$(python3 /opt/eledia/scripts/hash-password.py "${SOLR_SUPPORT_PASSWORD}")
    export SOLR_CUSTOMER_PASSWORD_HASH=$(python3 /opt/eledia/scripts/hash-password.py "${SOLR_CUSTOMER_PASSWORD}")

    echo "  [OK] Password hashes generated"

    # Save credentials to file (for user reference)
    CRED_FILE="/var/solr/credentials.txt"
    cat > "${CRED_FILE}" <<EOF
# Eledia Solr Credentials - ${CUSTOMER_NAME}
# Generated: $(date -Iseconds)
# ============================================================

Admin User:    ${SOLR_ADMIN_USER}
Admin Password: ${SOLR_ADMIN_PASSWORD}

Support User:    ${SOLR_SUPPORT_USER}
Support Password: ${SOLR_SUPPORT_PASSWORD}

Customer User:    ${SOLR_CUSTOMER_USER}
Customer Password: ${SOLR_CUSTOMER_PASSWORD}

# ============================================================
# IMPORTANT: Store these credentials securely!
# This file will be overwritten on container restart if
# passwords are not provided via environment variables.
# ============================================================
EOF
    chmod 600 "${CRED_FILE}"
    echo "  [SAVED] Credentials saved to: ${CRED_FILE}"
fi

# ============================================================
# CONFIGURATION GENERATION
# ============================================================

echo ""
echo "[2/7] Configuration Generation..."

CONFIG_DIR="/var/solr/data/configs"
LANG_DIR="/var/solr/data/lang"

# Ensure directories exist
mkdir -p "${CONFIG_DIR}"
mkdir -p "${LANG_DIR}"
mkdir -p /var/solr/backup/configs

# Generate security.json
if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
    echo "  [GENERATING] security.json..."

    export SOLR_ADMIN_USER SOLR_SUPPORT_USER SOLR_CUSTOMER_USER
    export SOLR_ADMIN_PASSWORD_HASH SOLR_SUPPORT_PASSWORD_HASH SOLR_CUSTOMER_PASSWORD_HASH

    envsubst < /opt/eledia/config-templates/security.json.template > /var/solr/data/security.json

    # Validate JSON syntax
    if ! jq empty /var/solr/data/security.json 2>/dev/null; then
        echo "  [ERROR] security.json validation failed!"
        exit 1
    fi

    chmod 600 /var/solr/data/security.json
    echo "  [OK] security.json generated and validated"
fi

# Generate solrconfig.xml
echo "  [GENERATING] solrconfig.xml..."
if [ -f /opt/eledia/config-templates/solrconfig.xml.template ]; then
    envsubst < /opt/eledia/config-templates/solrconfig.xml.template > "${CONFIG_DIR}/solrconfig.xml"

    # Validate XML syntax
    if ! xmllint --noout "${CONFIG_DIR}/solrconfig.xml" 2>/dev/null; then
        echo "  [ERROR] solrconfig.xml validation failed!"
        exit 1
    fi

    echo "  [OK] solrconfig.xml generated and validated"
fi

# Generate moodle_schema.xml (if enabled)
if [ "${SOLR_USE_MOODLE_SCHEMA}" = "true" ]; then
    echo "  [GENERATING] moodle_schema.xml..."
    if [ -f /opt/eledia/config-templates/moodle_schema.xml.template ]; then
        envsubst < /opt/eledia/config-templates/moodle_schema.xml.template > "${CONFIG_DIR}/moodle_schema.xml"

        # Validate XML syntax
        if ! xmllint --noout "${CONFIG_DIR}/moodle_schema.xml" 2>/dev/null; then
            echo "  [ERROR] moodle_schema.xml validation failed!"
            exit 1
        fi

        echo "  [OK] moodle_schema.xml generated and validated"
    fi
fi

# Copy static config files
echo "  [COPYING] Static config files..."
for file in stopwords_de.txt stopwords_en.txt stopwords.txt synonyms.txt protwords.txt; do
    if [ -f "/opt/eledia/config-templates/${file}" ]; then
        cp "/opt/eledia/config-templates/${file}" "${LANG_DIR}/" 2>/dev/null || true
        echo "    - ${file} → ${LANG_DIR}/"
    fi
done

# ============================================================
# PERMISSIONS
# ============================================================

echo ""
echo "[3/7] Setting permissions..."
chown -R solr:solr /var/solr
chmod 600 /var/solr/data/security.json 2>/dev/null || true
echo "  [OK] Permissions set (solr:solr)"

# ============================================================
# CONFIGURATION SUMMARY
# ============================================================

echo ""
echo "[4/7] Configuration Summary:"
echo "========================================"
ls -lah /var/solr/data/security.json 2>/dev/null || echo "security.json: NOT FOUND"
echo "---"
ls -lah "${CONFIG_DIR}/" 2>/dev/null || echo "configs/: EMPTY"
echo "---"
ls -lah "${LANG_DIR}/" 2>/dev/null || echo "lang/: EMPTY"
echo "========================================"

# ============================================================
# START SOLR
# ============================================================

echo ""
echo "[5/7] Starting Solr..."
echo "========================================"

# Start Solr in background for initialization
/opt/solr/bin/solr start -force -m "${SOLR_HEAP}"

# Wait for Solr to be ready
echo "[6/7] Waiting for Solr to be ready..."
MAX_WAIT=60
WAIT_COUNT=0
while ! curl -sf http://localhost:8983/solr/admin/ping?wt=json > /dev/null 2>&1; do
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ ${WAIT_COUNT} -ge ${MAX_WAIT} ]; then
        echo "  [ERROR] Solr did not start within ${MAX_WAIT} seconds"
        exit 1
    fi
    echo "  [WAITING] Attempt ${WAIT_COUNT}/${MAX_WAIT}..."
    sleep 1
done

echo "  [OK] Solr is ready!"

# ============================================================
# CORE CREATION
# ============================================================

echo ""
echo "[7/7] Core Creation..."

# Check if core already exists
CORE_EXISTS=$(curl -sf "http://localhost:8983/solr/admin/cores?action=STATUS&core=${SOLR_CORE_NAME}&wt=json" | jq -r ".status.${SOLR_CORE_NAME}.instanceDir // empty")

if [ -z "${CORE_EXISTS}" ]; then
    echo "  [CREATING] Core '${SOLR_CORE_NAME}'..."

    # Determine schema to use
    if [ "${SOLR_USE_MOODLE_SCHEMA}" = "true" ] && [ -f "${CONFIG_DIR}/moodle_schema.xml" ]; then
        SCHEMA_ARG="schema=${CONFIG_DIR}/moodle_schema.xml"
        echo "    Using Moodle schema"
    else
        SCHEMA_ARG=""
        echo "    Using default schema"
    fi

    # Create core with auth if enabled
    if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
        CREATE_RESPONSE=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
            "http://localhost:8983/solr/admin/cores?action=CREATE&name=${SOLR_CORE_NAME}&configSet=_default&wt=json" || echo '{"error":"failed"}')
    else
        CREATE_RESPONSE=$(curl -sf \
            "http://localhost:8983/solr/admin/cores?action=CREATE&name=${SOLR_CORE_NAME}&configSet=_default&wt=json" || echo '{"error":"failed"}')
    fi

    # Check if creation was successful
    if echo "${CREATE_RESPONSE}" | jq -e '.error' > /dev/null 2>&1; then
        echo "  [ERROR] Core creation failed!"
        echo "${CREATE_RESPONSE}" | jq .
        exit 1
    fi

    echo "  [OK] Core '${SOLR_CORE_NAME}' created successfully"
else
    echo "  [EXISTS] Core '${SOLR_CORE_NAME}' already exists"
fi

# ============================================================
# FINALIZATION
# ============================================================

echo ""
echo "========================================"
echo "Eledia Solr Initialization Complete!"
echo "========================================"
echo "  - Solr version: 9.9.0"
echo "  - Core name: ${SOLR_CORE_NAME}"
echo "  - Auth enabled: ${SOLR_AUTH_ENABLED}"
echo "  - Moodle schema: ${SOLR_USE_MOODLE_SCHEMA}"

if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
    echo ""
    echo "CREDENTIALS:"
    echo "  - Admin: ${SOLR_ADMIN_USER} / ${SOLR_ADMIN_PASSWORD}"
    echo "  - Support: ${SOLR_SUPPORT_USER} / ${SOLR_SUPPORT_PASSWORD}"
    echo "  - Customer: ${SOLR_CUSTOMER_USER} / ${SOLR_CUSTOMER_PASSWORD}"
    echo ""
    echo "  (Saved to: /var/solr/credentials.txt)"
fi

echo "========================================"
echo "Solr is ready at: http://localhost:8983/solr/"
echo "========================================"

# Stop background Solr
/opt/solr/bin/solr stop -all

# Start Solr in foreground (keeps container running)
exec /opt/solr/bin/solr start -f -m "${SOLR_HEAP}"
