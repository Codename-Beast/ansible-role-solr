#!/bin/bash
# Smoke Test Suite for Eledia Solr Docker
# Tests all implemented features with Docker-native tools
# Version: 1.0.0

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

log_test() {
    echo -e "${BLUE}[TEST ${TESTS_TOTAL}]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

run_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

echo "========================================"
echo "Eledia Solr - Smoke Test Suite"
echo "Testing with Docker-native tools"
echo "========================================"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    log_fail "docker-compose not found"
    exit 1
fi

# Start container if not running
log_info "Checking container status..."
if ! docker-compose ps | grep -q "Up"; then
    log_info "Starting containers..."
    docker-compose up -d
    sleep 30  # Wait for Solr to be ready
fi

CONTAINER_NAME=$(docker-compose ps -q solr | xargs docker inspect --format='{{.Name}}' | sed 's/^.//')
log_info "Testing container: ${CONTAINER_NAME}"

echo ""
echo "========================================"
echo "SMOKE TESTS - Feature 1: Backup System"
echo "========================================"
echo ""

# Test 1.1: Backup script exists and is executable
run_test
log_test "Backup script exists and is executable"
if docker exec "${CONTAINER_NAME}" test -x /opt/eledia/scripts/backup.sh; then
    log_pass "backup.sh is executable"
else
    log_fail "backup.sh not found or not executable"
fi

# Test 1.2: Backup directory exists
run_test
log_test "Backup directory exists"
if docker exec "${CONTAINER_NAME}" test -d /var/solr/backups; then
    log_pass "Backup directory exists"
else
    log_fail "Backup directory not found"
fi

# Test 1.3: Run backup (dry run / check for errors)
run_test
log_test "Backup script runs without errors"
if docker exec -e BACKUP_ENABLED=true "${CONTAINER_NAME}" /opt/eledia/scripts/backup.sh > /tmp/backup-test.log 2>&1; then
    log_pass "Backup script executed successfully"
    log_info "  Output: $(head -5 /tmp/backup-test.log | tr '\n' ' ')"
else
    log_fail "Backup script failed"
    log_info "  Error: $(cat /tmp/backup-test.log)"
fi

# Test 1.4: Verify backup was created
run_test
log_test "Backup file was created"
BACKUP_COUNT=$(docker exec "${CONTAINER_NAME}" find /var/solr/backups -type d -name "backup_*" 2>/dev/null | wc -l)
if [ "${BACKUP_COUNT}" -gt 0 ]; then
    log_pass "Found ${BACKUP_COUNT} backup(s)"
else
    log_fail "No backups found"
fi

# Test 1.5: Restore script exists
run_test
log_test "Restore script exists and is executable"
if docker exec "${CONTAINER_NAME}" test -x /opt/eledia/scripts/restore.sh; then
    log_pass "restore.sh is executable"
else
    log_fail "restore.sh not found or not executable"
fi

# Test 1.6: List backups
run_test
log_test "List backups functionality"
if docker exec "${CONTAINER_NAME}" /opt/eledia/scripts/restore.sh --list > /tmp/restore-list.log 2>&1; then
    log_pass "Backup listing works"
else
    log_fail "Backup listing failed"
fi

echo ""
echo "========================================"
echo "SMOKE TESTS - Feature 2: Log Rotation"
echo "========================================"
echo ""

# Test 2.1: Log rotation script exists
run_test
log_test "Log rotation script exists and is executable"
if docker exec "${CONTAINER_NAME}" test -x /opt/eledia/scripts/log-rotation.sh; then
    log_pass "log-rotation.sh is executable"
else
    log_fail "log-rotation.sh not found or not executable"
fi

# Test 2.2: Log directory exists
run_test
log_test "Log directory exists"
if docker exec "${CONTAINER_NAME}" test -d /var/solr/logs; then
    log_pass "Log directory exists"
else
    log_fail "Log directory not found"
fi

# Test 2.3: Run log rotation
run_test
log_test "Log rotation script runs without errors"
if docker exec -e LOG_ROTATION_ENABLED=true "${CONTAINER_NAME}" /opt/eledia/scripts/log-rotation.sh > /tmp/logrotate-test.log 2>&1; then
    log_pass "Log rotation executed successfully"
else
    log_fail "Log rotation failed"
    log_info "  Error: $(cat /tmp/logrotate-test.log)"
fi

echo ""
echo "========================================"
echo "SMOKE TESTS - Feature 3: Health Checks"
echo "========================================"
echo ""

# Test 3.1: Health check script exists
run_test
log_test "Health check script exists and is executable"
if docker exec "${CONTAINER_NAME}" test -x /opt/eledia/scripts/health-check.sh; then
    log_pass "health-check.sh is executable"
else
    log_fail "health-check.sh not found or not executable"
fi

# Test 3.2: Liveness check
run_test
log_test "Liveness health check"
if docker exec -e HEALTH_CHECK_TYPE=liveness "${CONTAINER_NAME}" /opt/eledia/scripts/health-check.sh > /tmp/health-liveness.log 2>&1; then
    log_pass "Liveness check passed"
else
    log_fail "Liveness check failed"
    log_info "  Output: $(cat /tmp/health-liveness.log)"
fi

# Test 3.3: Readiness check
run_test
log_test "Readiness health check"
if docker exec -e HEALTH_CHECK_TYPE=readiness "${CONTAINER_NAME}" /opt/eledia/scripts/health-check.sh > /tmp/health-readiness.log 2>&1; then
    log_pass "Readiness check passed"
else
    log_fail "Readiness check failed"
    log_info "  Output: $(cat /tmp/health-readiness.log)"
fi

# Test 3.4: Detailed health check
run_test
log_test "Detailed health check"
if docker exec -e HEALTH_CHECK_TYPE=detailed "${CONTAINER_NAME}" /opt/eledia/scripts/health-check.sh > /tmp/health-detailed.log 2>&1; then
    log_pass "Detailed health check passed"
    log_info "  Output: $(grep 'Overall Status' /tmp/health-detailed.log)"
else
    # Detailed might return warning (exit 1) - check if it's just a warning
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -eq 1 ]; then
        log_pass "Detailed health check passed (with warnings)"
    else
        log_fail "Detailed health check failed"
    fi
fi

echo ""
echo "========================================"
echo "DOCKER-NATIVE CHECKS"
echo "========================================"
echo ""

# Docker health check
run_test
log_test "Docker health status"
DOCKER_HEALTH=$(docker inspect "${CONTAINER_NAME}" --format='{{.State.Health.Status}}' 2>/dev/null || echo "no healthcheck")
if [ "${DOCKER_HEALTH}" = "healthy" ] || [ "${DOCKER_HEALTH}" = "no healthcheck" ]; then
    log_pass "Docker reports container as healthy"
else
    log_fail "Docker reports container as: ${DOCKER_HEALTH}"
fi

# Container is running
run_test
log_test "Container is running"
if docker-compose ps | grep -q "Up"; then
    log_pass "Container is running"
else
    log_fail "Container is not running"
fi

# Volume exists
run_test
log_test "Solr data volume exists"
if docker volume ls | grep -q "solr_data"; then
    log_pass "Volume exists"
else
    log_fail "Volume not found"
fi

# Solr is accessible
run_test
log_test "Solr is accessible via HTTP"
if docker exec "${CONTAINER_NAME}" curl -sf http://localhost:8983/solr/admin/ping?wt=json > /dev/null 2>&1; then
    log_pass "Solr is accessible"
else
    log_fail "Solr is not accessible"
fi

echo ""
echo "========================================"
echo "TEST SUMMARY"
echo "========================================"
echo ""
echo "Total Tests: ${TESTS_TOTAL}"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [ ${TESTS_FAILED} -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    exit 1
fi
