#!/bin/bash
# Enhanced Health Check Script
# Version: 1.0.0
# Provides detailed system health information

set -e

: "${SOLR_CORE_NAME:=moodle}"
: "${SOLR_ADMIN_USER:=admin}"
: "${HEALTH_CHECK_TYPE:=liveness}"  # liveness, readiness, detailed

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

STATUS_OK=0
STATUS_WARN=1
STATUS_ERROR=2

OVERALL_STATUS=${STATUS_OK}

check_solr_ping() {
    if curl -sf http://localhost:8983/solr/admin/ping?wt=json > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

check_core_health() {
    local CORE=$1

    if [ -n "${SOLR_ADMIN_PASSWORD}" ]; then
        CORE_STATUS=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
            "http://localhost:8983/solr/admin/cores?action=STATUS&core=${CORE}&wt=json" 2>&1)
    else
        CORE_STATUS=$(curl -sf \
            "http://localhost:8983/solr/admin/cores?action=STATUS&core=${CORE}&wt=json" 2>&1)
    fi

    if echo "${CORE_STATUS}" | jq -e ".status.${CORE}.instanceDir" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

check_memory() {
    # Get heap usage
    if [ -n "${SOLR_ADMIN_PASSWORD}" ]; then
        MEM_INFO=$(curl -sf -u "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" \
            "http://localhost:8983/solr/admin/metrics?group=jvm&wt=json" 2>&1)
    else
        MEM_INFO=$(curl -sf \
            "http://localhost:8983/solr/admin/metrics?group=jvm&wt=json" 2>&1)
    fi

    HEAP_USED=$(echo "${MEM_INFO}" | jq -r '.metrics["solr.jvm"]["memory.heap.used"] // 0' 2>/dev/null)
    HEAP_MAX=$(echo "${MEM_INFO}" | jq -r '.metrics["solr.jvm"]["memory.heap.max"] // 1' 2>/dev/null)

    if [ ${HEAP_USED} -gt 0 ] && [ ${HEAP_MAX} -gt 0 ]; then
        HEAP_PERCENT=$((HEAP_USED * 100 / HEAP_MAX))

        if [ ${HEAP_PERCENT} -gt 90 ]; then
            echo -e "${RED}CRITICAL${NC}: Heap usage at ${HEAP_PERCENT}%"
            return 2
        elif [ ${HEAP_PERCENT} -gt 75 ]; then
            echo -e "${YELLOW}WARNING${NC}: Heap usage at ${HEAP_PERCENT}%"
            return 1
        else
            echo -e "${GREEN}OK${NC}: Heap usage at ${HEAP_PERCENT}%"
            return 0
        fi
    fi

    return 0
}

check_disk() {
    DISK_USAGE=$(df -h /var/solr | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ ${DISK_USAGE} -gt 90 ]; then
        echo -e "${RED}CRITICAL${NC}: Disk usage at ${DISK_USAGE}%"
        return 2
    elif [ ${DISK_USAGE} -gt 80 ]; then
        echo -e "${YELLOW}WARNING${NC}: Disk usage at ${DISK_USAGE}%"
        return 1
    else
        echo -e "${GREEN}OK${NC}: Disk usage at ${DISK_USAGE}%"
        return 0
    fi
}

# Liveness check (is container alive?)
if [ "${HEALTH_CHECK_TYPE}" = "liveness" ]; then
    if check_solr_ping; then
        echo "✓ Solr is alive"
        exit 0
    else
        echo "✗ Solr is not responding"
        exit 1
    fi
fi

# Readiness check (is Solr ready to serve?)
if [ "${HEALTH_CHECK_TYPE}" = "readiness" ]; then
    if check_solr_ping && check_core_health "${SOLR_CORE_NAME}"; then
        echo "✓ Solr is ready"
        exit 0
    else
        echo "✗ Solr is not ready"
        exit 1
    fi
fi

# Detailed health check
if [ "${HEALTH_CHECK_TYPE}" = "detailed" ]; then
    echo "========================================"
    echo "Eledia Solr Health Check"
    echo "========================================"
    echo ""

    echo "🔍 Solr Status:"
    if check_solr_ping; then
        echo -e "  ${GREEN}✓${NC} Solr ping: OK"
    else
        echo -e "  ${RED}✗${NC} Solr ping: FAILED"
        OVERALL_STATUS=${STATUS_ERROR}
    fi

    echo ""
    echo "🔍 Core Health:"
    if check_core_health "${SOLR_CORE_NAME}"; then
        echo -e "  ${GREEN}✓${NC} Core ${SOLR_CORE_NAME}: OK"
    else
        echo -e "  ${RED}✗${NC} Core ${SOLR_CORE_NAME}: FAILED"
        OVERALL_STATUS=${STATUS_ERROR}
    fi

    echo ""
    echo "🔍 Memory:"
    check_memory
    MEM_STATUS=$?
    [ ${MEM_STATUS} -gt ${OVERALL_STATUS} ] && OVERALL_STATUS=${MEM_STATUS}

    echo ""
    echo "🔍 Disk:"
    check_disk
    DISK_STATUS=$?
    [ ${DISK_STATUS} -gt ${OVERALL_STATUS} ] && OVERALL_STATUS=${DISK_STATUS}

    echo ""
    echo "========================================"
    if [ ${OVERALL_STATUS} -eq ${STATUS_OK} ]; then
        echo -e "${GREEN}Overall Status: HEALTHY${NC}"
    elif [ ${OVERALL_STATUS} -eq ${STATUS_WARN} ]; then
        echo -e "${YELLOW}Overall Status: WARNING${NC}"
    else
        echo -e "${RED}Overall Status: CRITICAL${NC}"
    fi
    echo "========================================"

    exit ${OVERALL_STATUS}
fi

exit 0
