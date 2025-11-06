# Solr Moodle Docker - Operations Runbook

**Version**: 2.4.0
**Last Updated**: 2025-11-06
**Audience**: Operations Team, DevOps, SREs

## 📋 Table of Contents

1. [Emergency Contacts](#emergency-contacts)
2. [Service Overview](#service-overview)
3. [Incident Response](#incident-response)
4. [Common Issues & Solutions](#common-issues--solutions)
5. [Monitoring & Alerts](#monitoring--alerts)
6. [Backup & Recovery](#backup--recovery)
7. [Maintenance Procedures](#maintenance-procedures)
8. [Escalation Paths](#escalation-paths)
9. [Useful Commands](#useful-commands)
10. [Health Check Procedures](#health-check-procedures)

---

## 🚨 Emergency Contacts

| Role | Contact | Escalation Time |
|------|---------|-----------------|
| **Primary On-Call** | [Your Team] | Immediate |
| **Secondary On-Call** | [Backup Team] | +15 minutes |
| **Manager** | [Manager Name] | +30 minutes |
| **Vendor Support** | Apache Solr Community | +1 hour |

### Emergency Response SLA
- **P1 (Critical)**: Response within 15 minutes
- **P2 (High)**: Response within 1 hour
- **P3 (Medium)**: Response within 4 hours
- **P4 (Low)**: Response within 1 business day

---

## 🏗️ Service Overview

### Architecture

```
┌─────────────────────────────────────────────────┐
│             Frontend Network                     │
│         (External Access: 172.20.0.0/24)        │
│                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌──────────┐ │
│  │  Solr    │  │  Health API  │  │ Grafana  │ │
│  │  :8983   │  │   :8888      │  │  :3000   │ │
│  └────┬─────┘  └──────────────┘  └────┬─────┘ │
└───────┼─────────────────────────────────┼───────┘
        │                                 │
        │        ┌────────────────────────┘
        │        │
┌───────┼────────┼─────────────────────────────────┐
│       │  Backend Network (172.20.1.0/24)        │
│       │  (Internal Monitoring Only)             │
│       │                                          │
│  ┌────▼────┐  ┌──────────────┐  ┌────────────┐│
│  │Exporter │  │  Prometheus  │  │Alertmanager││
│  │  :9854  │  │   :9090      │  │   :9093    ││
│  └─────────┘  └──────────────┘  └────────────┘│
└──────────────────────────────────────────────────┘
```

### Key Components

| Component | Port | Purpose | Critical? |
|-----------|------|---------|-----------|
| **Solr** | 8983 | Search engine | ✅ Yes |
| **Health API** | 8888 | Status endpoint | ⚠️ Important |
| **Solr Exporter** | 9854 | Metrics | ⚠️ Important |
| **Prometheus** | 9090 | Metrics storage | ❌ Optional |
| **Grafana** | 3000 | Dashboards | ❌ Optional |
| **Alertmanager** | 9093 | Alert routing | ❌ Optional |

### Network Segmentation

- **Frontend Network (172.20.0.0/24)**: External access, Solr, Health API, Grafana
- **Backend Network (172.20.1.0/24)**: Internal monitoring, Prometheus, Alertmanager

---

## 🚨 Incident Response

### P1 - Critical (Solr Down)

**Symptoms**:
- Solr not responding on port 8983
- Health API returns status "unhealthy"
- Alert: `SolrInstanceDown`

**Immediate Actions** (First 5 minutes):

```bash
# 1. Check container status
docker compose ps

# 2. Check Solr logs
docker compose logs solr --tail=100

# 3. Check disk space
df -h

# 4. Check memory
free -h

# 5. Quick restart attempt
make restart
```

**Investigation Steps**:

1. **Check if container is running**:
   ```bash
   docker ps | grep solr
   ```
   - If not running: Check docker compose logs
   - If OOMKilled: Increase heap size in .env

2. **Check Solr logs for errors**:
   ```bash
   tail -f logs/solr.log
   # or
   docker compose logs solr -f
   ```
   - Look for: OutOfMemoryError, PermGen, GC overhead
   - Look for: Lock errors, index corruption

3. **Check health endpoint**:
   ```bash
   curl http://localhost:8983/solr/admin/ping
   ```

4. **Check system resources**:
   ```bash
   # Disk space
   df -h /var/lib/docker

   # Memory
   docker stats solr --no-stream

   # CPU
   top -bn1 | grep solr
   ```

**Recovery Actions**:

```bash
# If out of memory
1. Increase SOLR_HEAP_SIZE in .env
2. Restart: make restart

# If disk full
1. Clean old backups: find backups/ -mtime +30 -delete
2. Clean Docker: docker system prune -af
3. Restart: make restart

# If index corruption
1. Stop Solr: make stop
2. Restore from backup: cp -r backups/latest/* data/
3. Start: make start

# Last resort - recreate containers
make clean
make start
make create-core
```

**Communication Template**:

```
Subject: [P1] Solr Service Down - [CUSTOMER_NAME]

Status: INVESTIGATING / IDENTIFIED / RESOLVED
Impact: Search functionality unavailable for [X] users
Start Time: [YYYY-MM-DD HH:MM]
Current Action: [What you're doing now]
ETA: [When you expect resolution]

Updates will follow every 15 minutes.
```

---

### P2 - High (Performance Degradation)

**Symptoms**:
- Query latency > 1000ms (p95)
- Alert: `SolrSlowQueries`
- High CPU usage

**Investigation**:

```bash
# Check query performance
curl -s "http://localhost:8983/solr/admin/metrics?group=core" | jq '.metrics'

# Check active queries
docker compose exec solr curl localhost:8983/solr/admin/threads

# Check GC activity
docker compose logs solr | grep -i "gc"

# Check cache hit ratios
curl -s "http://localhost:8983/solr/admin/metrics?group=core" | \
  jq '.metrics."solr.core"[].CACHE'
```

**Resolution**:

```bash
# 1. Optimize index
curl "http://admin:password@localhost:8983/solr/CORE_NAME/update?optimize=true"

# 2. Increase heap if needed
# Edit .env: SOLR_HEAP_SIZE=4g
make restart

# 3. Clear caches (last resort)
curl "http://admin:password@localhost:8983/solr/admin/cores?action=RELOAD&core=CORE_NAME"
```

---

### P3 - Medium (Backup Failure)

**Symptoms**:
- Alert: `BackupFailed` (if configured)
- No recent backups in backups/ directory

**Investigation**:

```bash
# Check backup cron logs
docker compose logs backup-cron --tail=50

# Check disk space
df -h backups/

# Manual backup test
./scripts/backup.sh
```

**Resolution**:

```bash
# If disk full
find backups/ -mtime +30 -delete

# If permission issues
chmod 755 backups/
chown -R $(id -u):$(id -g) backups/

# Restart backup service
docker compose restart backup-cron
```

---

## 🔧 Common Issues & Solutions

### Issue: Container Won't Start

**Symptoms**: Container exits immediately after start

**Diagnosis**:
```bash
docker compose ps
docker compose logs solr
```

**Common Causes & Fixes**:

| Cause | Solution |
|-------|----------|
| Port already in use | `lsof -i :8983` - Kill conflicting process |
| Permission errors | `chmod -R 755 data/ logs/` |
| Config errors | Check `config/security.json` syntax |
| Memory issues | Increase `SOLR_HEAP_SIZE` in .env |

---

### Issue: Out of Memory

**Symptoms**:
- Container shows "Killed" status
- OOMKilled in docker inspect

**Solution**:
```bash
# 1. Check current memory
docker stats solr --no-stream

# 2. Increase heap
# Edit .env:
SOLR_HEAP_SIZE=4g
SOLR_MEMORY_LIMIT=6g

# 3. Restart
make restart

# 4. Monitor
watch docker stats solr
```

**Heap Sizing Guidelines**:

| Index Size | Documents | Heap | Total RAM |
|------------|-----------|------|-----------|
| < 1GB | < 1M | 1g | 2GB |
| 1-10GB | 1-10M | 2g | 4GB |
| 10-50GB | 10-50M | 4g | 8GB |
| > 50GB | > 50M | 8g | 16GB |

---

### Issue: Slow Queries

**Symptoms**: p95 latency > 1000ms

**Diagnosis**:
```bash
# Check query stats
curl "http://localhost:9854/metrics" | grep query_time

# Check slow query log
docker compose logs solr | grep -i "slow"
```

**Solutions**:

1. **Optimize Index**:
   ```bash
   curl "http://admin:password@localhost:8983/solr/CORE_NAME/update?optimize=true"
   ```

2. **Check Cache Settings**:
   ```bash
   # View cache stats
   curl "http://localhost:8983/solr/admin/metrics?group=core" | jq '.metrics."solr.core"[].CACHE'

   # Increase cache sizes in solrconfig.xml if needed
   ```

3. **Review Query Complexity**:
   - Check for wildcard queries (slow)
   - Check for large result sets
   - Consider faceting optimization

---

### Issue: Authentication Failures

**Symptoms**: 401 Unauthorized errors

**Diagnosis**:
```bash
# Test authentication
curl -u admin:password http://localhost:8983/solr/admin/ping

# Verify credentials
grep SOLR_ADMIN_PASSWORD .env
```

**Solution**:
```bash
# Regenerate security.json
./scripts/generate-config.sh

# Restart Solr
make restart

# Test again
make health
```

---

### Issue: Disk Space Full

**Symptoms**:
- Alerts: `DiskSpaceLow`
- Errors in logs about disk space

**Immediate Actions**:
```bash
# Check disk usage
df -h
du -sh data/ logs/ backups/

# Quick cleanup
find logs/ -mtime +7 -delete
find backups/ -mtime +30 -delete
docker system prune -af

# If still critical
# Stop Solr
make stop
# Move data to larger volume
# Restart
make start
```

---

## 📊 Monitoring & Alerts

### Key Metrics to Watch

| Metric | Threshold | Action |
|--------|-----------|--------|
| **Heap Usage** | > 90% | Increase heap |
| **GC Time** | > 5% | Tune GC or increase heap |
| **Query p95** | > 1000ms | Optimize queries/index |
| **Disk Usage** | > 80% | Clean up or expand |
| **Cache Hit Ratio** | < 80% | Increase cache size |
| **Error Rate** | > 1% | Investigate logs |

### Alert Runbooks

#### Alert: `SolrInstanceDown`

- **Severity**: Critical (P1)
- **Description**: Solr is not responding
- **Action**: Follow [P1 Incident Response](#p1---critical-solr-down)

#### Alert: `SolrHighMemoryUsage`

- **Severity**: High (P2)
- **Description**: Heap usage > 90%
- **Action**:
  ```bash
  # Check current usage
  docker stats solr --no-stream

  # Increase heap
  # Edit .env: SOLR_HEAP_SIZE=4g
  make restart
  ```

#### Alert: `SolrSlowQueries`

- **Severity**: Medium (P3)
- **Description**: p95 query latency > 1000ms
- **Action**: Follow [Slow Queries](#issue-slow-queries)

---

## 💾 Backup & Recovery

### Backup Procedures

**Automated (Daily)**:
```bash
# Backups run daily at 2:00 AM via cron
# Check backup service
docker compose ps backup-cron

# View backup logs
docker compose logs backup-cron
```

**Manual Backup**:
```bash
# Create backup
make backup

# or
./scripts/backup.sh

# Backups stored in: backups/backup_YYYYMMDD_HHMMSS/
```

### Recovery Procedures

**Full Recovery**:
```bash
# 1. Stop Solr
make stop

# 2. List backups
ls -lh backups/

# 3. Restore latest backup
cp -r backups/backup_20250106_020000/* data/

# 4. Start Solr
make start

# 5. Verify
make health
```

**Partial Recovery (Single Core)**:
```bash
# 1. List backups
ls backups/backup_*/

# 2. Restore specific core
cp -r backups/backup_YYYYMMDD_HHMMSS/data/CORE_NAME/* \
      data/CORE_NAME/

# 3. Reload core
curl "http://admin:password@localhost:8983/solr/admin/cores?action=RELOAD&core=CORE_NAME"
```

### Backup Verification

**Weekly Backup Test** (recommended):
```bash
# 1. Create test backup
make backup

# 2. Verify backup size
du -sh backups/backup_latest/

# 3. Test restore (in staging)
# ... restore to staging environment
# ... run smoke tests
```

---

## 🔧 Maintenance Procedures

### Routine Maintenance

**Daily**:
- ✅ Check monitoring dashboards
- ✅ Review alert history
- ✅ Verify backup completion

**Weekly**:
- ✅ Review disk usage trends
- ✅ Check slow query log
- ✅ Test backup restore (staging)
- ✅ Review security logs

**Monthly**:
- ✅ Index optimization
- ✅ Update Solr version (if available)
- ✅ Review and tune JVM settings
- ✅ Capacity planning review

### Planned Maintenance Windows

**Standard Maintenance**:
```bash
# 1. Announce maintenance window
# 2. Create backup
make backup

# 3. Put Solr in read-only mode (optional)
curl "http://admin:password@localhost:8983/solr/admin/collections?action=ADDREPLICA..."

# 4. Perform maintenance
make stop
# ... do maintenance ...
make start

# 5. Verify health
make health

# 6. Announce completion
```

### Index Optimization

**When to Optimize**:
- After large bulk imports
- Monthly maintenance
- Query performance degradation

**How to Optimize**:
```bash
# Optimize index (may take hours for large indexes)
curl "http://admin:password@localhost:8983/solr/CORE_NAME/update?optimize=true&maxSegments=1"

# Monitor optimization progress
docker compose logs solr -f | grep -i optimize
```

---

## 📞 Escalation Paths

### Escalation Matrix

| Time | Action | Contact |
|------|--------|---------|
| **0-15 min** | Initial response | Primary On-Call |
| **15-30 min** | If unresolved | Secondary On-Call |
| **30-60 min** | If still unresolved | Manager |
| **1+ hour** | Critical P1 only | Executive escalation |

### When to Escalate

- **Immediately escalate if**:
  - Data loss suspected
  - Security breach suspected
  - Unable to restore service within SLA
  - External vendor needed

---

## 🛠️ Useful Commands

### Quick Reference

```bash
# === Status Checks ===
make health                  # Full health check
docker compose ps           # Container status
curl localhost:8888/health  # Health API

# === Logs ===
make logs                   # Follow Solr logs
docker compose logs -f      # All services
docker compose logs backup-cron  # Backup logs

# === Restart ===
make restart                # Graceful restart
docker compose restart solr # Restart Solr only

# === Backup/Restore ===
make backup                 # Create backup
./scripts/backup.sh         # Manual backup
ls -lh backups/            # List backups

# === Monitoring ===
make grafana               # Open Grafana
make prometheus            # Open Prometheus
make metrics               # Show current metrics

# === Troubleshooting ===
docker stats solr          # Resource usage
docker compose exec solr bash  # Shell into container
curl localhost:8983/solr/admin/metrics  # Metrics

# === Emergency ===
make stop                  # Stop all services
make clean                 # Remove containers
make destroy               # Delete everything (⚠️ DANGEROUS)
```

---

## 🏥 Health Check Procedures

### Full Health Check

```bash
#!/bin/bash
# Comprehensive health check

echo "=== Solr Health Check ==="

# 1. Container Status
echo "1. Container Status:"
docker compose ps solr | grep Up && echo "✅ Running" || echo "❌ Down"

# 2. HTTP Endpoint
echo "2. HTTP Endpoint:"
curl -sf http://localhost:8983/solr/admin/ping > /dev/null && \
  echo "✅ Responding" || echo "❌ Not responding"

# 3. Health API
echo "3. Health API:"
STATUS=$(curl -s http://localhost:8888/health | jq -r '.status')
echo "Status: $STATUS"
[[ "$STATUS" == "healthy" ]] && echo "✅ Healthy" || echo "❌ Unhealthy"

# 4. Disk Space
echo "4. Disk Space:"
DISK_USAGE=$(df -h data/ | awk 'NR==2 {print $5}' | tr -d '%')
echo "Usage: ${DISK_USAGE}%"
[[ $DISK_USAGE -lt 80 ]] && echo "✅ OK" || echo "⚠️ High"

# 5. Memory
echo "5. Memory:"
MEM=$(docker stats solr --no-stream --format "{{.MemPerc}}" | tr -d '%')
echo "Usage: ${MEM}%"
[[ ${MEM%.*} -lt 90 ]] && echo "✅ OK" || echo "⚠️ High"

# 6. Last Backup
echo "6. Last Backup:"
LAST_BACKUP=$(ls -t backups/ | head -1)
BACKUP_AGE=$(find backups/ -maxdepth 1 -type d -mtime -1 | wc -l)
echo "Latest: $LAST_BACKUP"
[[ $BACKUP_AGE -gt 0 ]] && echo "✅ Recent" || echo "⚠️ Old"

echo ""
echo "=== Health Check Complete ==="
```

### Smoke Tests

```bash
# After any change, run smoke tests

# 1. Basic ping
curl -sf http://localhost:8983/solr/admin/ping

# 2. Query test
curl -sf "http://localhost:8983/solr/CORE_NAME/select?q=*:*&rows=1"

# 3. Index test
curl -sf -X POST "http://admin:password@localhost:8983/solr/CORE_NAME/update/json/docs" \
  -H "Content-Type: application/json" \
  -d '{"id":"test1","title":"Test"}'

# 4. Commit
curl -sf "http://admin:password@localhost:8983/solr/CORE_NAME/update?commit=true"

# 5. Verify indexed
curl -sf "http://localhost:8983/solr/CORE_NAME/select?q=id:test1"

# 6. Cleanup
curl -sf "http://admin:password@localhost:8983/solr/CORE_NAME/update?commit=true" \
  -H "Content-Type: text/xml" \
  -d '<delete><query>id:test1</query></delete>'
```

---

## 📚 Additional Resources

- **Solr Documentation**: https://solr.apache.org/guide/
- **Docker Compose Docs**: https://docs.docker.com/compose/
- **Project README**: README.md
- **Monitoring Guide**: MONITORING.md
- **Changelog**: CHANGELOG.md

---

**Document Version**: 2.4.0
**Last Review**: 2025-11-06
**Next Review**: 2025-12-06
**Owner**: Operations Team
