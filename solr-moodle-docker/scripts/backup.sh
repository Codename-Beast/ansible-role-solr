#!/bin/bash
# Eledia Solr Backup Script
# Version: 1.0.0
# Automated backup system with retention policy

set -e

# Load environment variables
: "${BACKUP_ENABLED:=false}"
: "${BACKUP_SCHEDULE:=0 2 * * *}"
: "${BACKUP_RETENTION_DAYS:=7}"
: "${BACKUP_DIR:=/var/solr/backups}"
: "${SOLR_CORE_NAME:=moodle}"
: "${SOLR_ADMIN_USER:=admin}"
: "${SOLR_ADMIN_PASSWORD}"
: "${DEBUG:=false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

debug_log() {
    if [ "${DEBUG}" = "true" ]; then
        echo -e "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# Check if backups are enabled
if [ "${BACKUP_ENABLED}" != "true" ]; then
    log_warn "Backups are disabled (BACKUP_ENABLED=false)"
    exit 0
fi

# Check if Solr is running
if ! curl -sf http://localhost:8983/solr/admin/ping?wt=json > /dev/null 2>&1; then
    log_error "Solr is not running or not accessible"
    exit 1
fi

log_info "Starting backup process for core: ${SOLR_CORE_NAME}"

# Create backup directory if not exists
mkdir -p "${BACKUP_DIR}"

# Generate backup name with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${SOLR_CORE_NAME}_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

debug_log "Backup will be stored at: ${BACKUP_PATH}"

# Trigger Solr backup via API
log_info "Triggering Solr backup API..."

if [ -n "${SOLR_ADMIN_PASSWORD}" ]; then
    # With authentication
    BACKUP_RESPONSE=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
        "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=backup&location=${BACKUP_DIR}&name=${BACKUP_NAME}&wt=json" 2>&1)
else
    # Without authentication
    BACKUP_RESPONSE=$(curl -sf \
        "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=backup&location=${BACKUP_DIR}&name=${BACKUP_NAME}&wt=json" 2>&1)
fi

BACKUP_EXIT_CODE=$?

if [ ${BACKUP_EXIT_CODE} -ne 0 ]; then
    log_error "Backup API call failed"
    log_error "Response: ${BACKUP_RESPONSE}"
    exit 1
fi

debug_log "Backup API response: ${BACKUP_RESPONSE}"

# Check if backup was successful
if echo "${BACKUP_RESPONSE}" | jq -e '.status == "OK"' > /dev/null 2>&1; then
    log_info "✓ Backup triggered successfully"
else
    log_error "Backup API returned error"
    echo "${BACKUP_RESPONSE}" | jq .
    exit 1
fi

# Wait for backup to complete (poll status)
log_info "Waiting for backup to complete..."
MAX_WAIT=300  # 5 minutes
WAIT_COUNT=0

while [ ${WAIT_COUNT} -lt ${MAX_WAIT} ]; do
    if [ -n "${SOLR_ADMIN_PASSWORD}" ]; then
        STATUS_RESPONSE=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
            "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=details&wt=json" 2>&1)
    else
        STATUS_RESPONSE=$(curl -sf \
            "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=details&wt=json" 2>&1)
    fi

    # Check if backup is still in progress
    BACKUP_STATUS=$(echo "${STATUS_RESPONSE}" | jq -r '.details.backup[0].status // "unknown"' 2>/dev/null)

    if [ "${BACKUP_STATUS}" = "success" ]; then
        log_info "✓ Backup completed successfully"
        break
    elif [ "${BACKUP_STATUS}" = "failed" ]; then
        log_error "Backup failed!"
        echo "${STATUS_RESPONSE}" | jq '.details.backup[0]'
        exit 1
    fi

    WAIT_COUNT=$((WAIT_COUNT + 5))
    sleep 5
done

if [ ${WAIT_COUNT} -ge ${MAX_WAIT} ]; then
    log_error "Backup did not complete within ${MAX_WAIT} seconds"
    exit 1
fi

# Verify backup exists
if [ ! -d "${BACKUP_PATH}" ]; then
    log_error "Backup directory not found: ${BACKUP_PATH}"
    exit 1
fi

# Get backup size
BACKUP_SIZE=$(du -sh "${BACKUP_PATH}" | cut -f1)
log_info "Backup size: ${BACKUP_SIZE}"

# Create metadata file
METADATA_FILE="${BACKUP_PATH}/backup.metadata"
cat > "${METADATA_FILE}" <<EOF
{
  "backup_name": "${BACKUP_NAME}",
  "core_name": "${SOLR_CORE_NAME}",
  "timestamp": "${TIMESTAMP}",
  "date_human": "$(date '+%Y-%m-%d %H:%M:%S')",
  "backup_size": "${BACKUP_SIZE}",
  "solr_version": "9.9.0",
  "status": "success"
}
EOF

log_info "Metadata written to: ${METADATA_FILE}"

# Cleanup old backups (retention policy)
log_info "Applying retention policy (${BACKUP_RETENTION_DAYS} days)..."

find "${BACKUP_DIR}" -maxdepth 1 -type d -name "backup_${SOLR_CORE_NAME}_*" -mtime +${BACKUP_RETENTION_DAYS} | while read -r OLD_BACKUP; do
    log_warn "Removing old backup: $(basename ${OLD_BACKUP})"
    rm -rf "${OLD_BACKUP}"
done

# Count remaining backups
BACKUP_COUNT=$(find "${BACKUP_DIR}" -maxdepth 1 -type d -name "backup_${SOLR_CORE_NAME}_*" | wc -l)
log_info "Total backups: ${BACKUP_COUNT}"

# List all backups
log_info "Available backups:"
find "${BACKUP_DIR}" -maxdepth 1 -type d -name "backup_${SOLR_CORE_NAME}_*" -printf "%T@ %p\n" | \
    sort -rn | \
    head -10 | \
    while read -r TIMESTAMP_UNIX BACKUP_PATH_ITEM; do
        BACKUP_NAME_ITEM=$(basename "${BACKUP_PATH_ITEM}")
        BACKUP_SIZE_ITEM=$(du -sh "${BACKUP_PATH_ITEM}" 2>/dev/null | cut -f1)
        BACKUP_DATE=$(date -d "@${TIMESTAMP_UNIX}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
        log_info "  - ${BACKUP_NAME_ITEM} (${BACKUP_SIZE_ITEM}) - ${BACKUP_DATE}"
    done

log_info "========================================="
log_info "Backup completed successfully!"
log_info "Backup location: ${BACKUP_PATH}"
log_info "Backup size: ${BACKUP_SIZE}"
log_info "========================================="

exit 0
