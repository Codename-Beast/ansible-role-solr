#!/bin/bash
# Log Rotation Script
# Version: 1.0.0

set -e

: "${LOG_ROTATION_ENABLED:=true}"
: "${LOG_MAX_SIZE:=100M}"
: "${LOG_MAX_FILES:=10}"
: "${LOG_COMPRESSION:=true}"
: "${DEBUG:=false}"

LOG_DIR="/var/solr/logs"

if [ "${LOG_ROTATION_ENABLED}" != "true" ]; then
    [ "${DEBUG}" = "true" ] && echo "Log rotation disabled"
    exit 0
fi

# Convert size format (100M -> 100)
MAX_SIZE_NUM=$(echo "${LOG_MAX_SIZE}" | sed 's/[^0-9]//g')
MAX_SIZE_UNIT=$(echo "${LOG_MAX_SIZE}" | sed 's/[0-9]//g' | tr '[:lower:]' '[:upper:]')

case ${MAX_SIZE_UNIT} in
    M|MB)
        MAX_SIZE_BYTES=$((MAX_SIZE_NUM * 1024 * 1024))
        ;;
    G|GB)
        MAX_SIZE_BYTES=$((MAX_SIZE_NUM * 1024 * 1024 * 1024))
        ;;
    K|KB)
        MAX_SIZE_BYTES=$((MAX_SIZE_NUM * 1024))
        ;;
    *)
        MAX_SIZE_BYTES=$((MAX_SIZE_NUM * 1024 * 1024))  # Default to MB
        ;;
esac

[ "${DEBUG}" = "true" ] && echo "Max log size: ${MAX_SIZE_BYTES} bytes"

# Rotate logs
for LOG_FILE in "${LOG_DIR}"/*.log; do
    [ ! -f "${LOG_FILE}" ] && continue

    FILE_SIZE=$(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)

    if [ ${FILE_SIZE} -gt ${MAX_SIZE_BYTES} ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        ROTATED_NAME="${LOG_FILE}.${TIMESTAMP}"

        [ "${DEBUG}" = "true" ] && echo "Rotating: ${LOG_FILE} -> ${ROTATED_NAME}"

        mv "${LOG_FILE}" "${ROTATED_NAME}"
        touch "${LOG_FILE}"

        # Compress if enabled
        if [ "${LOG_COMPRESSION}" = "true" ]; then
            gzip "${ROTATED_NAME}"
            [ "${DEBUG}" = "true" ] && echo "Compressed: ${ROTATED_NAME}.gz"
        fi
    fi
done

# Cleanup old rotated logs
ROTATED_COUNT=$(find "${LOG_DIR}" -name "*.log.*" | wc -l)
if [ ${ROTATED_COUNT} -gt ${LOG_MAX_FILES} ]; then
    [ "${DEBUG}" = "true" ] && echo "Cleaning up old logs (keeping ${LOG_MAX_FILES})"

    find "${LOG_DIR}" -name "*.log.*" -type f -printf '%T@ %p\n' | \
        sort -rn | \
        tail -n +$((LOG_MAX_FILES + 1)) | \
        cut -d' ' -f2 | \
        xargs rm -f
fi

[ "${DEBUG}" = "true" ] && echo "Log rotation complete"
