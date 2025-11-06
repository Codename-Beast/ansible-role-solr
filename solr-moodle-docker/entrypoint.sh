#!/bin/bash

# Eledia Solr Entrypoint Script
# Version: 2.1.0
# Handles initialization, config generation, and Solr startup
# WITH ENHANCED ERROR HANDLING AND DEBUG MODE

# ============================================================
# DEBUG MODE SETUP
# ============================================================
# Enable with: DEBUG=true
: "${DEBUG:=false}"

if [ "${DEBUG}" = "true" ]; then
    set -x  # Print all commands
    echo "========================================"
    echo "DEBUG MODE ENABLED"
    echo "All commands will be printed"
    echo "========================================"
else
    set -e  # Exit on error
fi

# Error handler function
error_exit() {
    local error_message="$1"
    local error_code="${2:-1}"
    local help_text="$3"

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                         ERROR DETECTED                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "❌ ERROR: ${error_message}"
    echo ""

    if [ -n "${help_text}" ]; then
        echo "💡 HELP:"
        echo "${help_text}"
        echo ""
    fi

    if [ "${DEBUG}" = "true" ]; then
        echo "🔍 DEBUG INFO:"
        echo "  - Working directory: $(pwd)"
        echo "  - User: $(whoami)"
        echo "  - UID/GID: $(id)"
        echo "  - Environment variables:"
        env | grep -E "^SOLR_|^CUSTOMER_" | sort
        echo ""
        echo "  - Directory structure:"
        ls -la /var/solr/ 2>/dev/null || echo "    /var/solr/ not accessible"
        ls -la /opt/eledia/ 2>/dev/null || echo "    /opt/eledia/ not accessible"
        echo ""
    fi

    echo "🔧 TROUBLESHOOTING:"
    echo "  1. Enable DEBUG mode: docker-compose up with DEBUG=true"
    echo "  2. Check logs: docker-compose logs -f solr"
    echo "  3. Inspect container: docker exec -it <container> bash"
    echo "  4. Verify .env file settings"
    echo ""
    echo "📚 Documentation: See solr-moodle-docker/README.md"
    echo ""

    exit "${error_code}"
}

# Warning function
warn() {
    local warning_message="$1"
    echo ""
    echo "⚠️  WARNING: ${warning_message}"
    echo ""
}

# Debug log function
debug_log() {
    if [ "${DEBUG}" = "true" ]; then
        echo "🔍 DEBUG: $1"
    fi
}

echo "========================================"
echo "Eledia Solr 9.9.0 - Moodle Edition"
echo "Version: 2.2.0 (Backup, Log Rotation, Health Checks)"
echo "========================================"

if [ "${DEBUG}" = "true" ]; then
    echo "⚡ DEBUG MODE: ON"
fi

# ============================================================
# PREREQUISITES CHECK
# ============================================================

echo ""
echo "[0/7] Prerequisites Check..."

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    error_exit \
        "jq is not installed" \
        10 \
        "jq is required for JSON validation and processing.
  The Dockerfile should install jq. If you're building from scratch,
  ensure the Dockerfile contains: RUN apt-get install -y jq"
fi
debug_log "jq: OK"

# Check if xmllint is available
if ! command -v xmllint >/dev/null 2>&1; then
    error_exit \
        "xmllint is not installed" \
        11 \
        "xmllint is required for XML validation.
  The Dockerfile should install libxml2-utils. If you're building from scratch,
  ensure the Dockerfile contains: RUN apt-get install -y libxml2-utils"
fi
debug_log "xmllint: OK"

# Check if python3 is available
if ! command -v python3 >/dev/null 2>&1; then
    error_exit \
        "python3 is not installed" \
        12 \
        "python3 is required for password hashing.
  The Dockerfile should install python3. If you're building from scratch,
  ensure the Dockerfile contains: RUN apt-get install -y python3 python3-pip"
fi
debug_log "python3: OK"

# Check if hash-password.py exists
if [ ! -f /opt/eledia/scripts/hash-password.py ]; then
    error_exit \
        "hash-password.py script not found" \
        13 \
        "The password hashing script is missing.
  Expected location: /opt/eledia/scripts/hash-password.py
  Check if the Docker image was built correctly and all files were copied."
fi
debug_log "hash-password.py: OK"

# Check if config templates directory exists
if [ ! -d /opt/eledia/config-templates ]; then
    error_exit \
        "Config templates directory not found" \
        14 \
        "The config templates directory is missing.
  Expected location: /opt/eledia/config-templates/
  Check if the Docker image was built correctly and COPY command succeeded."
fi
debug_log "config-templates/: OK"

echo "  [OK] All prerequisites satisfied"

# ============================================================
# ENVIRONMENT VARIABLE VALIDATION
# ============================================================

echo ""
echo "[1/9] Environment Variable Validation..."

# Required variables with validation
: "${SOLR_AUTH_ENABLED:=true}"
: "${SOLR_USE_MOODLE_SCHEMA:=false}"
: "${SOLR_CORE_NAME:=moodle}"
: "${CUSTOMER_NAME:=default}"

# Validate SOLR_AUTH_ENABLED
if [[ ! "${SOLR_AUTH_ENABLED}" =~ ^(true|false)$ ]]; then
    error_exit \
        "Invalid value for SOLR_AUTH_ENABLED: '${SOLR_AUTH_ENABLED}'" \
        20 \
        "SOLR_AUTH_ENABLED must be 'true' or 'false'
  Current value: ${SOLR_AUTH_ENABLED}
  Fix: Set SOLR_AUTH_ENABLED=true or SOLR_AUTH_ENABLED=false in your .env file"
fi

# Validate SOLR_USE_MOODLE_SCHEMA
if [[ ! "${SOLR_USE_MOODLE_SCHEMA}" =~ ^(true|false)$ ]]; then
    error_exit \
        "Invalid value for SOLR_USE_MOODLE_SCHEMA: '${SOLR_USE_MOODLE_SCHEMA}'" \
        21 \
        "SOLR_USE_MOODLE_SCHEMA must be 'true' or 'false'
  Current value: ${SOLR_USE_MOODLE_SCHEMA}
  Fix: Set SOLR_USE_MOODLE_SCHEMA=true or SOLR_USE_MOODLE_SCHEMA=false in your .env file"
fi

# Validate SOLR_CORE_NAME (no spaces, alphanumeric + underscore/dash)
if [[ ! "${SOLR_CORE_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error_exit \
        "Invalid SOLR_CORE_NAME: '${SOLR_CORE_NAME}'" \
        22 \
        "SOLR_CORE_NAME must contain only letters, numbers, underscores, and dashes.
  Current value: '${SOLR_CORE_NAME}'
  Examples of valid names: 'moodle', 'my_core', 'core-01', 'production_solr'
  Fix: Update SOLR_CORE_NAME in your .env file"
fi

# Validate CUSTOMER_NAME
if [[ ! "${CUSTOMER_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error_exit \
        "Invalid CUSTOMER_NAME: '${CUSTOMER_NAME}'" \
        23 \
        "CUSTOMER_NAME must contain only letters, numbers, underscores, and dashes.
  Current value: '${CUSTOMER_NAME}'
  Fix: Update CUSTOMER_NAME in your .env file"
fi

# Auth variables (optional - will be generated if not provided)
: "${SOLR_ADMIN_USER:=admin}"
: "${SOLR_SUPPORT_USER:=support}"
: "${SOLR_CUSTOMER_USER:=customer}"

# Validate usernames (no spaces, no special chars except underscore)
for user_var in SOLR_ADMIN_USER SOLR_SUPPORT_USER SOLR_CUSTOMER_USER; do
    user_value="${!user_var}"
    if [[ ! "${user_value}" =~ ^[a-zA-Z0-9_]+$ ]]; then
        error_exit \
            "Invalid ${user_var}: '${user_value}'" \
            24 \
            "${user_var} must contain only letters, numbers, and underscores.
  Current value: '${user_value}'
  Fix: Update ${user_var} in your .env file"
    fi
done

# Optional variables with defaults
: "${SOLR_HEAP:=512m}"
: "${SOLR_JAVA_MEM:=-Xms512m -Xmx512m}"
: "${SOLR_LOG_LEVEL:=INFO}"

# Validate SOLR_HEAP format (must be like 512m, 1g, 2G, etc.)
if [[ ! "${SOLR_HEAP}" =~ ^[0-9]+[mMgG]$ ]]; then
    error_exit \
        "Invalid SOLR_HEAP format: '${SOLR_HEAP}'" \
        25 \
        "SOLR_HEAP must be in format like '512m', '1g', '2G'
  Current value: '${SOLR_HEAP}'
  Examples: 512m (512 megabytes), 1g (1 gigabyte), 2G (2 gigabytes)
  Fix: Update SOLR_HEAP in your .env file"
fi

echo "  [OK] All environment variables validated"

echo ""
echo "[INFO] Configuration:"
echo "  - Auth enabled: ${SOLR_AUTH_ENABLED}"
echo "  - Moodle schema: ${SOLR_USE_MOODLE_SCHEMA}"
echo "  - Core name: ${SOLR_CORE_NAME}"
echo "  - Customer: ${CUSTOMER_NAME}"
echo "  - Heap size: ${SOLR_HEAP}"
echo "  - Admin user: ${SOLR_ADMIN_USER}"
echo "  - Support user: ${SOLR_SUPPORT_USER}"
echo "  - Customer user: ${SOLR_CUSTOMER_USER}"

if [ "${DEBUG}" = "true" ]; then
    echo ""
    echo "🔍 DEBUG: Full environment"
    env | grep -E "^SOLR_|^CUSTOMER_" | sort
fi

# ============================================================
# PASSWORD GENERATION / VALIDATION
# ============================================================

generate_password() {
    # Generate secure random password (24 characters)
    if ! tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 24 2>/dev/null; then
        error_exit \
            "Failed to generate random password" \
            30 \
            "Password generation using /dev/urandom failed.
  This might indicate a system issue with random number generation.
  Try:
    1. Check if /dev/urandom exists: ls -la /dev/urandom
    2. Check if tr and head commands are available
  Workaround: Provide passwords manually via environment variables"
    fi
}

if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
    echo ""
    echo "[2/9] Password Management..."

    # Generate passwords if not provided
    if [ -z "${SOLR_ADMIN_PASSWORD}" ]; then
        export SOLR_ADMIN_PASSWORD=$(generate_password)
        echo "  [GENERATED] Admin password: ${SOLR_ADMIN_PASSWORD}"
    else
        echo "  [PROVIDED] Admin password: ********"
        # Validate password strength
        if [ ${#SOLR_ADMIN_PASSWORD} -lt 8 ]; then
            warn "Admin password is less than 8 characters. Consider using a stronger password."
        fi
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

    debug_log "Hashing admin password..."
    if ! SOLR_ADMIN_PASSWORD_HASH=$(python3 /opt/eledia/scripts/hash-password.py "${SOLR_ADMIN_PASSWORD}" 2>&1); then
        error_exit \
            "Failed to hash admin password" \
            31 \
            "Password hashing script failed.
  Error output: ${SOLR_ADMIN_PASSWORD_HASH}
  Check if:
    1. Python3 passlib module is installed: pip3 list | grep passlib
    2. hash-password.py script is executable and error-free
  Debug: docker exec <container> python3 /opt/eledia/scripts/hash-password.py 'testpass'"
    fi
    export SOLR_ADMIN_PASSWORD_HASH

    debug_log "Hashing support password..."
    if ! SOLR_SUPPORT_PASSWORD_HASH=$(python3 /opt/eledia/scripts/hash-password.py "${SOLR_SUPPORT_PASSWORD}" 2>&1); then
        error_exit "Failed to hash support password" 31
    fi
    export SOLR_SUPPORT_PASSWORD_HASH

    debug_log "Hashing customer password..."
    if ! SOLR_CUSTOMER_PASSWORD_HASH=$(python3 /opt/eledia/scripts/hash-password.py "${SOLR_CUSTOMER_PASSWORD}" 2>&1); then
        error_exit "Failed to hash customer password" 31
    fi
    export SOLR_CUSTOMER_PASSWORD_HASH

    echo "  [OK] Password hashes generated"

    # Save credentials to file (for user reference)
    CRED_FILE="/var/solr/credentials.txt"
    if ! cat > "${CRED_FILE}" <<EOF
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
    then
        error_exit \
            "Failed to write credentials file" \
            32 \
            "Could not write to ${CRED_FILE}
  Check:
    1. Volume permissions: docker volume inspect <volume_name>
    2. Disk space: df -h
    3. Directory exists: ls -la /var/solr/
  The container might not have write access to /var/solr/"
    fi

    chmod 600 "${CRED_FILE}" || warn "Could not set permissions on credentials file"
    echo "  [SAVED] Credentials saved to: ${CRED_FILE}"
fi

# ============================================================
# CONFIGURATION GENERATION
# ============================================================

echo ""
echo "[3/9] Configuration Generation..."

CONFIG_DIR="/var/solr/data/configs"
LANG_DIR="/var/solr/data/lang"

# Ensure directories exist
debug_log "Creating directories: ${CONFIG_DIR}, ${LANG_DIR}, /var/solr/backup/configs"
if ! mkdir -p "${CONFIG_DIR}" "${LANG_DIR}" /var/solr/backup/configs 2>/dev/null; then
    error_exit \
        "Failed to create required directories" \
        40 \
        "Could not create directories in /var/solr/
  Check:
    1. Volume mount: docker-compose.yml volumes section
    2. Permissions: ls -la /var/solr/
    3. User/Group: Current user is $(whoami) with UID $(id -u)
  The solr user (UID 8983) needs write access to /var/solr/"
fi

# Generate security.json
if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
    echo "  [GENERATING] security.json..."

    SECURITY_TEMPLATE="/opt/eledia/config-templates/security.json.template"
    if [ ! -f "${SECURITY_TEMPLATE}" ]; then
        error_exit \
            "security.json template not found" \
            41 \
            "Template file missing: ${SECURITY_TEMPLATE}
  This indicates the Docker image was not built correctly.
  Solution: Rebuild the image with 'docker-compose build --no-cache'"
    fi

    export SOLR_ADMIN_USER SOLR_SUPPORT_USER SOLR_CUSTOMER_USER
    export SOLR_ADMIN_PASSWORD_HASH SOLR_SUPPORT_PASSWORD_HASH SOLR_CUSTOMER_PASSWORD_HASH
    export SOLR_CORE_NAME

    debug_log "Running envsubst on ${SECURITY_TEMPLATE}"
    if ! envsubst < "${SECURITY_TEMPLATE}" > /var/solr/data/security.json 2>/dev/null; then
        error_exit \
            "Failed to generate security.json from template" \
            42 \
            "envsubst failed to process the template.
  Check:
    1. Template syntax: cat ${SECURITY_TEMPLATE}
    2. Environment variables are exported
    3. Write permissions to /var/solr/data/
  Debug: docker exec <container> envsubst < ${SECURITY_TEMPLATE}"
    fi

    # Validate JSON syntax
    debug_log "Validating JSON syntax of security.json"
    JSON_ERROR=$(jq empty /var/solr/data/security.json 2>&1)
    if [ $? -ne 0 ]; then
        error_exit \
            "security.json validation failed - Invalid JSON syntax" \
            43 \
            "Generated security.json contains syntax errors:
  ${JSON_ERROR}

  This might be caused by:
    1. Invalid characters in usernames or environment variables
    2. Missing environment variable substitution
    3. Template corruption

  Debug steps:
    1. View generated file: docker exec <container> cat /var/solr/data/security.json
    2. Test template: docker exec <container> cat ${SECURITY_TEMPLATE}
    3. Validate manually: jq empty /var/solr/data/security.json"
    fi

    if ! chmod 600 /var/solr/data/security.json 2>/dev/null; then
        warn "Could not set restrictive permissions on security.json (chmod 600 failed)"
    fi

    echo "  [OK] security.json generated and validated"
fi

# Generate solrconfig.xml
echo "  [GENERATING] solrconfig.xml..."
SOLRCONFIG_TEMPLATE="/opt/eledia/config-templates/solrconfig.xml.template"

if [ ! -f "${SOLRCONFIG_TEMPLATE}" ]; then
    error_exit \
        "solrconfig.xml template not found" \
        44 \
        "Template file missing: ${SOLRCONFIG_TEMPLATE}
  Rebuild the Docker image: docker-compose build --no-cache"
fi

export CUSTOMER_NAME
debug_log "Generating solrconfig.xml for customer: ${CUSTOMER_NAME}"

if ! envsubst < "${SOLRCONFIG_TEMPLATE}" > "${CONFIG_DIR}/solrconfig.xml" 2>/dev/null; then
    error_exit \
        "Failed to generate solrconfig.xml" \
        45 \
        "envsubst failed. Check write permissions to ${CONFIG_DIR}/"
fi

# Validate XML syntax
debug_log "Validating XML syntax of solrconfig.xml"
XML_ERROR=$(xmllint --noout "${CONFIG_DIR}/solrconfig.xml" 2>&1)
if [ $? -ne 0 ]; then
    error_exit \
        "solrconfig.xml validation failed - Invalid XML syntax" \
        46 \
        "Generated solrconfig.xml contains syntax errors:
  ${XML_ERROR}

  Debug:
    1. View file: docker exec <container> cat ${CONFIG_DIR}/solrconfig.xml
    2. Check template: cat ${SOLRCONFIG_TEMPLATE}
    3. Validate: xmllint --noout ${CONFIG_DIR}/solrconfig.xml"
fi

echo "  [OK] solrconfig.xml generated and validated"

# Generate moodle_schema.xml (if enabled)
if [ "${SOLR_USE_MOODLE_SCHEMA}" = "true" ]; then
    echo "  [GENERATING] moodle_schema.xml..."
    SCHEMA_TEMPLATE="/opt/eledia/config-templates/moodle_schema.xml.template"

    if [ ! -f "${SCHEMA_TEMPLATE}" ]; then
        error_exit \
            "moodle_schema.xml template not found" \
            47 \
            "SOLR_USE_MOODLE_SCHEMA is set to 'true' but template is missing.
  Expected: ${SCHEMA_TEMPLATE}
  Solution:
    1. Rebuild image: docker-compose build --no-cache
    2. Or disable Moodle schema: SOLR_USE_MOODLE_SCHEMA=false"
    fi

    if ! envsubst < "${SCHEMA_TEMPLATE}" > "${CONFIG_DIR}/moodle_schema.xml" 2>/dev/null; then
        error_exit "Failed to generate moodle_schema.xml" 48
    fi

    # Validate XML syntax
    debug_log "Validating XML syntax of moodle_schema.xml"
    XML_ERROR=$(xmllint --noout "${CONFIG_DIR}/moodle_schema.xml" 2>&1)
    if [ $? -ne 0 ]; then
        error_exit \
            "moodle_schema.xml validation failed" \
            49 \
            "XML syntax errors in moodle_schema.xml:
  ${XML_ERROR}

  Debug: docker exec <container> xmllint --noout ${CONFIG_DIR}/moodle_schema.xml"
    fi

    echo "  [OK] moodle_schema.xml generated and validated"
fi

# Copy static config files
echo "  [COPYING] Static config files..."
COPIED_COUNT=0
for file in stopwords_de.txt stopwords_en.txt stopwords.txt synonyms.txt protwords.txt; do
    if [ -f "/opt/eledia/config-templates/${file}" ]; then
        if cp "/opt/eledia/config-templates/${file}" "${LANG_DIR}/" 2>/dev/null; then
            echo "    ✓ ${file} → ${LANG_DIR}/"
            COPIED_COUNT=$((COPIED_COUNT + 1))
        else
            warn "Could not copy ${file} to ${LANG_DIR}/"
        fi
    else
        debug_log "Optional file not found: ${file}"
    fi
done

if [ ${COPIED_COUNT} -eq 0 ]; then
    warn "No static config files were copied. This is OK if you don't need stopwords/synonyms."
fi

# ============================================================
# PERMISSIONS
# ============================================================

echo ""
echo "[4/9] Setting permissions..."

debug_log "Setting ownership: chown -R solr:solr /var/solr"
if ! chown -R solr:solr /var/solr 2>/dev/null; then
    # This might fail if we're not root, but that's OK in some scenarios
    warn "Could not set ownership to solr:solr (this might be OK if already correct)"
fi

chmod 600 /var/solr/data/security.json 2>/dev/null || true
echo "  [OK] Permissions set"

# ============================================================
# CONFIGURATION SUMMARY
# ============================================================

echo ""
echo "[5/9] Configuration Summary:"
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
echo "[6/9] Starting Solr..."
echo "========================================"

# Check if port 8983 is already in use (within container)
if netstat -tuln 2>/dev/null | grep -q ':8983 '; then
    error_exit \
        "Port 8983 is already in use" \
        50 \
        "Another process is listening on port 8983.
  Check:
    1. Is another Solr instance running? ps aux | grep solr
    2. Container restart issue? Try: docker-compose down && docker-compose up
  Debug: netstat -tuln | grep 8983"
fi

# Start Solr in background for initialization
debug_log "Starting Solr with: /opt/solr/bin/solr start -force -m ${SOLR_HEAP}"
SOLR_START_OUTPUT=$(/opt/solr/bin/solr start -force -m "${SOLR_HEAP}" 2>&1)
SOLR_START_CODE=$?

if [ ${SOLR_START_CODE} -ne 0 ]; then
    error_exit \
        "Solr failed to start" \
        51 \
        "Solr startup command failed with exit code ${SOLR_START_CODE}
  Output:
  ${SOLR_START_OUTPUT}

  Common causes:
    1. Insufficient memory (current heap: ${SOLR_HEAP})
    2. Invalid Java options: ${SOLR_JAVA_MEM}
    3. Port conflict
    4. Corrupted Solr installation

  Debug:
    1. Check Java: java -version
    2. Check memory: free -h
    3. Try manual start: /opt/solr/bin/solr start -f -m ${SOLR_HEAP}"
fi

echo "  [OK] Solr process started"

# ============================================================
# WAIT FOR SOLR READINESS
# ============================================================

echo ""
echo "[7/9] Waiting for Solr to be ready..."

MAX_WAIT=60
WAIT_COUNT=0
LAST_ERROR=""

while ! curl -sf http://localhost:8983/solr/admin/ping?wt=json > /dev/null 2>&1; do
    WAIT_COUNT=$((WAIT_COUNT + 1))

    if [ ${WAIT_COUNT} -ge ${MAX_WAIT} ]; then
        # Try to get more info about why Solr is not responding
        SOLR_LOGS=$(/opt/solr/bin/solr status 2>&1 || echo "Could not get Solr status")

        error_exit \
            "Solr did not become ready within ${MAX_WAIT} seconds" \
            52 \
            "Solr started but is not responding to health checks.
  Solr status:
  ${SOLR_LOGS}

  Possible causes:
    1. Solr is still starting up (try increasing MAX_WAIT)
    2. Configuration error preventing startup
    3. Out of memory (check heap size: ${SOLR_HEAP})
    4. Security.json configuration error

  Debug:
    1. Check Solr logs: docker exec <container> cat /var/solr/logs/solr.log
    2. Check process: docker exec <container> ps aux | grep solr
    3. Try manual ping: docker exec <container> curl http://localhost:8983/solr/admin/ping
    4. Check ports: docker exec <container> netstat -tuln | grep 8983"
    fi

    # Show progress every 5 seconds
    if [ $((WAIT_COUNT % 5)) -eq 0 ]; then
        echo "  [WAITING] Still waiting... (${WAIT_COUNT}/${MAX_WAIT} seconds)"
        debug_log "Checking Solr status..."
        if [ "${DEBUG}" = "true" ]; then
            curl -sf http://localhost:8983/solr/admin/ping?wt=json 2>&1 || echo "    Ping failed"
        fi
    else
        echo -n "."
    fi

    sleep 1
done

echo ""
echo "  [OK] Solr is ready and responding!"

# ============================================================
# CORE CREATION
# ============================================================

echo ""
echo "[8/9] Core Creation..."

# Check if core already exists
debug_log "Checking if core '${SOLR_CORE_NAME}' exists..."
CORE_STATUS=$(curl -sf "http://localhost:8983/solr/admin/cores?action=STATUS&core=${SOLR_CORE_NAME}&wt=json" 2>&1)
CORE_CHECK_CODE=$?

if [ ${CORE_CHECK_CODE} -ne 0 ]; then
    error_exit \
        "Failed to check core status" \
        60 \
        "Could not query Solr admin API.
  Error: ${CORE_STATUS}

  Check:
    1. Is Solr actually running? ps aux | grep solr
    2. Is the admin API accessible? curl http://localhost:8983/solr/admin/cores
    3. Are there authentication issues?

  This should not happen if Solr passed health check."
fi

CORE_EXISTS=$(echo "${CORE_STATUS}" | jq -r ".status.${SOLR_CORE_NAME}.instanceDir // empty" 2>/dev/null)

if [ -z "${CORE_EXISTS}" ]; then
    echo "  [CREATING] Core '${SOLR_CORE_NAME}'..."

    # Determine schema to use
    if [ "${SOLR_USE_MOODLE_SCHEMA}" = "true" ] && [ -f "${CONFIG_DIR}/moodle_schema.xml" ]; then
        SCHEMA_ARG="schema=${CONFIG_DIR}/moodle_schema.xml"
        echo "    Using Moodle schema"
        debug_log "Schema file: ${CONFIG_DIR}/moodle_schema.xml"
    else
        SCHEMA_ARG=""
        echo "    Using default schema"
    fi

    # Create core with auth if enabled
    if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
        debug_log "Creating core with authentication (user: ${SOLR_ADMIN_USER})"
        CREATE_RESPONSE=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
            "http://localhost:8983/solr/admin/cores?action=CREATE&name=${SOLR_CORE_NAME}&configSet=_default&wt=json" 2>&1)
        CREATE_CODE=$?
    else
        debug_log "Creating core without authentication"
        CREATE_RESPONSE=$(curl -sf \
            "http://localhost:8983/solr/admin/cores?action=CREATE&name=${SOLR_CORE_NAME}&configSet=_default&wt=json" 2>&1)
        CREATE_CODE=$?
    fi

    if [ ${CREATE_CODE} -ne 0 ]; then
        error_exit \
            "Core creation request failed" \
            61 \
            "Could not send core creation request to Solr.
  Error: ${CREATE_RESPONSE}

  Possible causes:
    1. Authentication failed (wrong password?)
    2. Network issue within container
    3. Solr API not accessible

  Debug:
    1. Test auth: curl -u ${SOLR_ADMIN_USER}:PASSWORD http://localhost:8983/solr/admin/cores
    2. Check credentials: cat /var/solr/credentials.txt
    3. Verify security.json: cat /var/solr/data/security.json"
    fi

    # Check if creation was successful
    debug_log "Core creation response: ${CREATE_RESPONSE}"

    if echo "${CREATE_RESPONSE}" | jq -e '.error' > /dev/null 2>&1; then
        ERROR_MSG=$(echo "${CREATE_RESPONSE}" | jq -r '.error.msg // "Unknown error"' 2>/dev/null)
        ERROR_CODE=$(echo "${CREATE_RESPONSE}" | jq -r '.error.code // 0' 2>/dev/null)

        error_exit \
            "Core creation failed: ${ERROR_MSG}" \
            62 \
            "Solr rejected the core creation request.
  Error code: ${ERROR_CODE}
  Full response: ${CREATE_RESPONSE}

  Common causes:
    1. Core name already exists (check with different name)
    2. ConfigSet '_default' not available
    3. Permission denied (security.json misconfigured)
    4. Disk space full

  Debug:
    1. List cores: curl http://localhost:8983/solr/admin/cores?action=STATUS
    2. Check configsets: ls -la /var/solr/data/configsets/
    3. Try different core name: SOLR_CORE_NAME=test_core"
    fi

    echo "  [OK] Core '${SOLR_CORE_NAME}' created successfully"
else
    echo "  [EXISTS] Core '${SOLR_CORE_NAME}' already exists"
    debug_log "Core instanceDir: ${CORE_EXISTS}"
fi

# Verify core is accessible
debug_log "Verifying core is accessible..."
if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
    CORE_PING=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
        "http://localhost:8983/solr/${SOLR_CORE_NAME}/admin/ping?wt=json" 2>&1)
else
    CORE_PING=$(curl -sf "http://localhost:8983/solr/${SOLR_CORE_NAME}/admin/ping?wt=json" 2>&1)
fi

if [ $? -ne 0 ] || ! echo "${CORE_PING}" | jq -e '.status == "OK"' > /dev/null 2>&1; then
    warn "Core was created but ping check failed. Core might not be fully initialized yet."
    debug_log "Core ping response: ${CORE_PING}"
else
    debug_log "Core ping successful: OK"
fi

# ============================================================
# AUTOMATION SETUP (Backups, Log Rotation, Health Checks)
# ============================================================

echo ""
echo "[9/9] Automation Setup..."

# Set up backup automation via cron
: "${BACKUP_ENABLED:=false}"
if [ "${BACKUP_ENABLED}" = "true" ]; then
    debug_log "Setting up backup automation..."
    if [ -x /opt/eledia/scripts/setup-cron.sh ]; then
        /opt/eledia/scripts/setup-cron.sh
        echo "  [OK] Backup automation configured"
    else
        warn "setup-cron.sh not found or not executable - backups will need to be run manually"
    fi
else
    echo "  [SKIP] Backup automation disabled (BACKUP_ENABLED=false)"
fi

# Run initial health check (optional - for diagnostics)
if [ "${DEBUG}" = "true" ] && [ -x /opt/eledia/scripts/health-check.sh ]; then
    echo ""
    echo "  [DEBUG] Running initial health check..."
    HEALTH_CHECK_TYPE=detailed /opt/eledia/scripts/health-check.sh || warn "Initial health check reported warnings"
fi

echo "  [OK] Automation setup complete"

# ============================================================
# FINALIZATION
# ============================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Eledia Solr Initialization Complete! ✓               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Configuration Summary:"
echo "  - Solr version: 9.9.0"
echo "  - Core name: ${SOLR_CORE_NAME}"
echo "  - Customer: ${CUSTOMER_NAME}"
echo "  - Auth enabled: ${SOLR_AUTH_ENABLED}"
echo "  - Moodle schema: ${SOLR_USE_MOODLE_SCHEMA}"
echo "  - Heap size: ${SOLR_HEAP}"
echo ""
echo "🔧 Features:"
echo "  - Backups: ${BACKUP_ENABLED:-false}"
if [ "${BACKUP_ENABLED}" = "true" ]; then
    echo "    Schedule: ${BACKUP_SCHEDULE:-0 2 * * *}"
    echo "    Retention: ${BACKUP_RETENTION_DAYS:-7} days"
fi
echo "  - Log Rotation: ${LOG_ROTATION_ENABLED:-true}"
if [ "${LOG_ROTATION_ENABLED}" = "true" ]; then
    echo "    Max size: ${LOG_MAX_SIZE:-100M}, Max files: ${LOG_MAX_FILES:-10}"
fi
echo "  - Health Checks: Available (/opt/eledia/scripts/health-check.sh)"

if [ "${SOLR_AUTH_ENABLED}" = "true" ]; then
    echo ""
    echo "🔐 CREDENTIALS:"
    echo "  - Admin:    ${SOLR_ADMIN_USER} / ${SOLR_ADMIN_PASSWORD}"
    echo "  - Support:  ${SOLR_SUPPORT_USER} / ${SOLR_SUPPORT_PASSWORD}"
    echo "  - Customer: ${SOLR_CUSTOMER_USER} / ${SOLR_CUSTOMER_PASSWORD}"
    echo ""
    echo "  💾 Saved to: /var/solr/credentials.txt"
    echo "  📖 View with: docker exec <container> cat /var/solr/credentials.txt"
fi

echo ""
echo "✅ Solr is ready at: http://localhost:8983/solr/"
echo ""

if [ "${DEBUG}" = "true" ]; then
    echo "🔍 DEBUG: Final system state"
    echo "Solr status:"
    /opt/solr/bin/solr status || true
    echo ""
    echo "Cores:"
    curl -sf "http://localhost:8983/solr/admin/cores?action=STATUS&wt=json" | jq -r '.status | keys[]' 2>/dev/null || echo "Could not list cores"
    echo ""
fi

echo "========================================="
echo "Stopping background Solr for foreground restart..."
echo "========================================="

# Stop background Solr
debug_log "Stopping background Solr..."
/opt/solr/bin/solr stop -all 2>&1 || warn "Could not stop background Solr cleanly"

sleep 2

echo ""
echo "🚀 Starting Solr in foreground mode (container will stay running)..."
echo ""

# Start Solr in foreground (keeps container running)
debug_log "Executing: /opt/solr/bin/solr start -f -m ${SOLR_HEAP}"
exec /opt/solr/bin/solr start -f -m "${SOLR_HEAP}"
