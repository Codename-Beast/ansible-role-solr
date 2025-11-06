#!/bin/bash
# Eledia Solr Restore Script
# Version: 1.0.0
# Restore from backup with validation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --list                    List available backups"
    echo "  --backup-name NAME        Restore specific backup by name"
    echo "  --latest                  Restore latest backup"
    echo "  --backup-dir DIR          Backup directory (default: /var/solr/backups)"
    echo "  --core NAME               Target core name (default: moodle)"
    echo "  --verify                  Verify backup before restore"
    echo "  --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --list"
    echo "  $0 --latest --verify"
    echo "  $0 --backup-name backup_moodle_20251106_020000"
    exit 1
}

# Default values
BACKUP_DIR="${BACKUP_DIR:-/var/solr/backups}"
SOLR_CORE_NAME="${SOLR_CORE_NAME:-moodle}"
SOLR_ADMIN_USER="${SOLR_ADMIN_USER:-admin}"
BACKUP_NAME=""
LIST_ONLY=false
USE_LATEST=false
VERIFY_BACKUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --list)
            LIST_ONLY=true
            shift
            ;;
        --backup-name)
            BACKUP_NAME="$2"
            shift 2
            ;;
        --latest)
            USE_LATEST=true
            shift
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --core)
            SOLR_CORE_NAME="$2"
            shift 2
            ;;
        --verify)
            VERIFY_BACKUP=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# List backups
list_backups() {
    log_info "Available backups in ${BACKUP_DIR}:"
    echo ""

    if [ ! -d "${BACKUP_DIR}" ]; then
        log_error "Backup directory not found: ${BACKUP_DIR}"
        exit 1
    fi

    BACKUP_COUNT=0
    find "${BACKUP_DIR}" -maxdepth 1 -type d -name "backup_${SOLR_CORE_NAME}_*" -printf "%T@ %p\n" | \
        sort -rn | \
        while read -r TIMESTAMP_UNIX BACKUP_PATH_ITEM; do
            BACKUP_COUNT=$((BACKUP_COUNT + 1))
            BACKUP_NAME_ITEM=$(basename "${BACKUP_PATH_ITEM}")
            BACKUP_SIZE_ITEM=$(du -sh "${BACKUP_PATH_ITEM}" 2>/dev/null | cut -f1)
            BACKUP_DATE=$(date -d "@${TIMESTAMP_UNIX}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")

            # Read metadata if exists
            METADATA_FILE="${BACKUP_PATH_ITEM}/backup.metadata"
            if [ -f "${METADATA_FILE}" ]; then
                BACKUP_STATUS=$(jq -r '.status // "unknown"' "${METADATA_FILE}" 2>/dev/null)
                echo -e "${BLUE}[$BACKUP_COUNT]${NC} ${BACKUP_NAME_ITEM}"
                echo "    Date: ${BACKUP_DATE}"
                echo "    Size: ${BACKUP_SIZE_ITEM}"
                echo "    Status: ${BACKUP_STATUS}"
                echo ""
            else
                echo -e "${BLUE}[$BACKUP_COUNT]${NC} ${BACKUP_NAME_ITEM}"
                echo "    Date: ${BACKUP_DATE}"
                echo "    Size: ${BACKUP_SIZE_ITEM}"
                echo "    Status: unknown (no metadata)"
                echo ""
            fi
        done

    if [ ${BACKUP_COUNT} -eq 0 ]; then
        log_warn "No backups found for core: ${SOLR_CORE_NAME}"
    fi
}

# Handle --list
if [ "${LIST_ONLY}" = true ]; then
    list_backups
    exit 0
fi

# Determine backup to restore
if [ "${USE_LATEST}" = true ]; then
    log_info "Finding latest backup..."
    LATEST_BACKUP=$(find "${BACKUP_DIR}" -maxdepth 1 -type d -name "backup_${SOLR_CORE_NAME}_*" -printf "%T@ %p\n" | \
        sort -rn | head -1 | cut -d' ' -f2)

    if [ -z "${LATEST_BACKUP}" ]; then
        log_error "No backups found"
        exit 1
    fi

    BACKUP_NAME=$(basename "${LATEST_BACKUP}")
    log_info "Latest backup: ${BACKUP_NAME}"
elif [ -n "${BACKUP_NAME}" ]; then
    LATEST_BACKUP="${BACKUP_DIR}/${BACKUP_NAME}"
    if [ ! -d "${LATEST_BACKUP}" ]; then
        log_error "Backup not found: ${BACKUP_NAME}"
        exit 1
    fi
else
    log_error "Please specify --backup-name or --latest"
    usage
fi

BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

log_info "========================================="
log_info "Restore Configuration"
log_info "========================================="
log_info "Backup: ${BACKUP_NAME}"
log_info "Core: ${SOLR_CORE_NAME}"
log_info "Path: ${BACKUP_PATH}"
log_info "========================================="

# Verify backup
if [ "${VERIFY_BACKUP}" = true ]; then
    log_info "Verifying backup integrity..."

    # Check if backup directory exists and is readable
    if [ ! -d "${BACKUP_PATH}" ] || [ ! -r "${BACKUP_PATH}" ]; then
        log_error "Backup directory is not accessible"
        exit 1
    fi

    # Check for essential Solr backup files
    REQUIRED_FILES=("index.properties" "snapshot_metadata")
    for FILE in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "${BACKUP_PATH}/${FILE}" ]; then
            log_warn "Missing file: ${FILE} (might be OK for some backup types)"
        fi
    done

    # Check backup size
    BACKUP_SIZE=$(du -sb "${BACKUP_PATH}" | cut -f1)
    if [ ${BACKUP_SIZE} -lt 1024 ]; then
        log_error "Backup seems too small (< 1KB), possibly corrupted"
        exit 1
    fi

    log_info "✓ Backup verification passed"
fi

# Check if Solr is running
if ! curl -sf http://localhost:8983/solr/admin/ping?wt=json > /dev/null 2>&1; then
    log_error "Solr is not running or not accessible"
    exit 1
fi

# Confirm restore
echo ""
log_warn "⚠️  WARNING: This will replace the current index!"
echo -n "Are you sure you want to restore? (yes/no): "
read -r CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    log_info "Restore cancelled"
    exit 0
fi

# Trigger restore via Solr API
log_info "Starting restore process..."

if [ -n "${SOLR_ADMIN_PASSWORD}" ]; then
    RESTORE_RESPONSE=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
        "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=restore&location=${BACKUP_DIR}&name=${BACKUP_NAME}&wt=json" 2>&1)
else
    RESTORE_RESPONSE=$(curl -sf \
        "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=restore&location=${BACKUP_DIR}&name=${BACKUP_NAME}&wt=json" 2>&1)
fi

RESTORE_EXIT_CODE=$?

if [ ${RESTORE_EXIT_CODE} -ne 0 ]; then
    log_error "Restore API call failed"
    log_error "Response: ${RESTORE_RESPONSE}"
    exit 1
fi

# Check response
if echo "${RESTORE_RESPONSE}" | jq -e '.status == "OK"' > /dev/null 2>&1; then
    log_info "✓ Restore triggered successfully"
else
    log_error "Restore API returned error"
    echo "${RESTORE_RESPONSE}" | jq .
    exit 1
fi

# Wait for restore to complete
log_info "Waiting for restore to complete..."
MAX_WAIT=600  # 10 minutes
WAIT_COUNT=0

while [ ${WAIT_COUNT} -lt ${MAX_WAIT} ]; do
    if [ -n "${SOLR_ADMIN_PASSWORD}" ]; then
        STATUS_RESPONSE=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
            "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=restorestatus&wt=json" 2>&1)
    else
        STATUS_RESPONSE=$(curl -sf \
            "http://localhost:8983/solr/${SOLR_CORE_NAME}/replication?command=restorestatus&wt=json" 2>&1)
    fi

    RESTORE_STATUS=$(echo "${STATUS_RESPONSE}" | jq -r '.restorestatus.status // "unknown"' 2>/dev/null)

    if [ "${RESTORE_STATUS}" = "success" ]; then
        log_info "✓ Restore completed successfully"
        break
    elif [ "${RESTORE_STATUS}" = "failed" ]; then
        log_error "Restore failed!"
        echo "${STATUS_RESPONSE}" | jq '.restorestatus'
        exit 1
    fi

    WAIT_COUNT=$((WAIT_COUNT + 5))
    echo -n "."
    sleep 5
done

echo ""

if [ ${WAIT_COUNT} -ge ${MAX_WAIT} ]; then
    log_error "Restore did not complete within ${MAX_WAIT} seconds"
    exit 1
fi

# Verify core is accessible after restore
log_info "Verifying core accessibility..."
if [ -n "${SOLR_ADMIN_PASSWORD}" ]; then
    PING_RESPONSE=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
        "http://localhost:8983/solr/${SOLR_CORE_NAME}/admin/ping?wt=json" 2>&1)
else
    PING_RESPONSE=$(curl -sf \
        "http://localhost:8983/solr/${SOLR_CORE_NAME}/admin/ping?wt=json" 2>&1)
fi

if echo "${PING_RESPONSE}" | jq -e '.status == "OK"' > /dev/null 2>&1; then
    log_info "✓ Core is accessible"
else
    log_error "Core ping failed after restore"
    exit 1
fi

log_info "========================================="
log_info "Restore completed successfully!"
log_info "========================================="
log_info "Restored from: ${BACKUP_NAME}"
log_info "Core: ${SOLR_CORE_NAME}"
log_info "========================================="

exit 0
