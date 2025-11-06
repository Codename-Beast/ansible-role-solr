# Test Guide - Eledia Solr Docker

**Version**: 1.0.0
**Zweck**: Vollständige Testanleitung für alle implementierten Features

---

## 🚀 Quick Start: Alle Tests ausführen

```bash
cd solr-moodle-docker

# Build image
docker-compose build

# Start container
docker-compose up -d

# Wait for Solr to be ready (30 seconds)
sleep 30

# Run smoke tests
./tests/smoke-test.sh

# Expected output: "✓ ALL TESTS PASSED"
```

---

## 📋 TEST SUITE ÜBERSICHT

**Gesamt**: 17 Smoke Tests
**Features getestet**: 3
**Docker-Tools genutzt**: docker exec, docker-compose, docker inspect, docker volume

---

## 🧪 FEATURE 1: Backup System (6 Tests)

### Test 1.1: Backup Script Existenz
**Was wird getestet**: Backup-Script ist vorhanden und ausführbar
**Command**:
```bash
docker exec test_solr test -x /opt/eledia/scripts/backup.sh
echo $?  # Sollte 0 sein
```
**Erwartetes Ergebnis**: Exit Code 0
**Fehlerfall**: Exit Code 1 → Script fehlt oder nicht executable

---

### Test 1.2: Backup Directory Existenz
**Was wird getestet**: Backup-Verzeichnis existiert
**Command**:
```bash
docker exec test_solr test -d /var/solr/backups
echo $?
```
**Erwartetes Ergebnis**: Exit Code 0
**Fehlerfall**: Directory wurde nicht erstellt

---

### Test 1.3: Backup Execution
**Was wird getestet**: Backup läuft ohne Fehler
**Command**:
```bash
docker exec -e BACKUP_ENABLED=true test_solr /opt/eledia/scripts/backup.sh
echo $?
```
**Erwartetes Ergebnis**:
- Exit Code 0
- Output enthält "[INFO]" Messages
- Output enthält "Backup completed successfully"

**Fehlerfall-Diagnose**:
```bash
# Check Solr status
docker exec test_solr curl http://localhost:8983/solr/admin/ping

# Check permissions
docker exec test_solr ls -la /var/solr/backups

# Check logs
docker exec test_solr cat /var/solr/logs/backup.log
```

---

### Test 1.4: Backup File Creation
**Was wird getestet**: Backup-Files wurden erstellt
**Command**:
```bash
docker exec test_solr find /var/solr/backups -type d -name "backup_*"
```
**Erwartetes Ergebnis**:
- Mindestens 1 Backup-Directory gefunden
- Format: `backup_moodle_YYYYMMDD_HHMMSS`

**Validation**:
```bash
# Check backup contents
docker exec test_solr ls -la /var/solr/backups/backup_moodle_*/

# Expected files:
# - snapshot_metadata
# - index.properties
# - segments_*
```

---

### Test 1.5: Restore Script Existenz
**Was wird getestet**: Restore-Script ist vorhanden
**Command**:
```bash
docker exec test_solr test -x /opt/eledia/scripts/restore.sh
echo $?
```
**Erwartetes Ergebnis**: Exit Code 0

---

### Test 1.6: Backup Listing
**Was wird getestet**: Backups können gelistet werden
**Command**:
```bash
docker exec test_solr /opt/eledia/scripts/restore.sh --list
```
**Erwartetes Ergebnis**:
- Output zeigt verfügbare Backups
- Format: `[1] backup_moodle_YYYYMMDD_HHMMSS`
- Zeigt Datum, Größe, Status

**Manuelle Validierung**:
```bash
# Should list all backups
docker exec test_solr /opt/eledia/scripts/restore.sh --list | grep "backup_"

# Count backups
docker exec test_solr find /var/solr/backups -name "backup_*" -type d | wc -l
```

---

## 🧪 FEATURE 2: Log Rotation (3 Tests)

### Test 2.1: Log Rotation Script Existenz
**Command**:
```bash
docker exec test_solr test -x /opt/eledia/scripts/log-rotation.sh
```
**Erwartetes Ergebnis**: Exit Code 0

---

### Test 2.2: Log Directory Existenz
**Command**:
```bash
docker exec test_solr test -d /var/solr/logs
```
**Erwartetes Ergebnis**: Exit Code 0

---

### Test 2.3: Log Rotation Execution
**Command**:
```bash
docker exec -e LOG_ROTATION_ENABLED=true test_solr /opt/eledia/scripts/log-rotation.sh
```
**Erwartetes Ergebnis**: Exit Code 0

**Test mit großen Logs**:
```bash
# Create large log file (>100MB)
docker exec test_solr dd if=/dev/zero of=/var/solr/logs/test.log bs=1M count=150

# Run rotation
docker exec test_solr /opt/eledia/scripts/log-rotation.sh

# Check if rotated
docker exec test_solr ls -la /var/solr/logs/ | grep "test.log"

# Expected: test.log (small) + test.log.YYYYMMDD_HHMMSS.gz (compressed)
```

---

## 🧪 FEATURE 3: Health Checks (4 Tests)

### Test 3.1: Health Check Script Existenz
**Command**:
```bash
docker exec test_solr test -x /opt/eledia/scripts/health-check.sh
```
**Erwartetes Ergebnis**: Exit Code 0

---

### Test 3.2: Liveness Check
**Was wird getestet**: Container ist alive
**Command**:
```bash
docker exec -e HEALTH_CHECK_TYPE=liveness test_solr /opt/eledia/scripts/health-check.sh
```
**Erwartetes Ergebnis**:
- Exit Code 0
- Output: "✓ Solr is alive"

---

### Test 3.3: Readiness Check
**Was wird getestet**: Solr ist bereit für Requests
**Command**:
```bash
docker exec -e HEALTH_CHECK_TYPE=readiness test_solr /opt/eledia/scripts/health-check.sh
```
**Erwartetes Ergebnis**:
- Exit Code 0
- Output: "✓ Solr is ready"

**Fehlerfall-Diagnose**:
```bash
# Check Solr status
docker exec test_solr curl http://localhost:8983/solr/admin/cores?action=STATUS

# Check core
docker exec test_solr curl http://localhost:8983/solr/moodle/admin/ping
```

---

### Test 3.4: Detailed Health Check
**Was wird getestet**: Alle Systemkomponenten
**Command**:
```bash
docker exec -e HEALTH_CHECK_TYPE=detailed test_solr /opt/eledia/scripts/health-check.sh
```
**Erwartetes Ergebnis**:
- Exit Code 0, 1 (warning), oder 2 (critical)
- Output zeigt:
  - Solr Status: OK
  - Core Health: OK
  - Memory: XX% (mit Status)
  - Disk: XX% (mit Status)
  - Overall Status: HEALTHY / WARNING / CRITICAL

**Interpretation**:
- Exit 0 + "HEALTHY" = Alles OK ✅
- Exit 1 + "WARNING" = Warnings vorhanden ⚠️ (z.B. Memory >75%)
- Exit 2 + "CRITICAL" = Kritische Probleme ❌ (z.B. Memory >90%)

---

## 🐳 DOCKER-NATIVE TESTS (4 Tests)

### Test D.1: Docker Health Status
**Command**:
```bash
docker inspect test_solr --format='{{.State.Health.Status}}'
```
**Erwartetes Ergebnis**: `healthy` oder `no healthcheck`

---

### Test D.2: Container Running
**Command**:
```bash
docker-compose ps | grep Up
```
**Erwartetes Ergebnis**: Container status enthält "Up"

---

### Test D.3: Volume Existenz
**Command**:
```bash
docker volume ls | grep solr_data
```
**Erwartetes Ergebnis**: Volume existiert

---

### Test D.4: Solr Accessibility
**Command**:
```bash
docker exec test_solr curl -sf http://localhost:8983/solr/admin/ping?wt=json
```
**Erwartetes Ergebnis**:
- Exit Code 0
- JSON Response mit `"status":"OK"`

---

## 🔍 MANUELLE TESTS (3x pro Feature)

### Backup System - Voller Test-Zyklus

#### Test-Run 1: Happy Path
```bash
# 1. Create backup
docker exec test_solr /opt/eledia/scripts/backup.sh

# 2. Verify backup exists
docker exec test_solr ls -la /var/solr/backups/

# 3. Add test document
docker exec test_solr curl -X POST \
  'http://localhost:8983/solr/moodle/update?commit=true' \
  -H 'Content-Type: application/json' \
  -d '[{"id":"test1","title":"Test Doc"}]'

# 4. Restore backup (will remove test doc)
docker exec test_solr /opt/eledia/scripts/restore.sh --latest --verify

# 5. Verify test doc is gone (restore worked)
docker exec test_solr curl \
  'http://localhost:8983/solr/moodle/select?q=id:test1'
# Should return 0 results
```

#### Test-Run 2: Error Handling
```bash
# 1. Stop Solr
docker exec test_solr /opt/solr/bin/solr stop -all

# 2. Try to backup (should fail gracefully)
docker exec test_solr /opt/eledia/scripts/backup.sh
# Expected: Clear error message, no crash

# 3. Restart Solr
docker-compose restart

# 4. Retry backup (should work now)
docker exec test_solr /opt/eledia/scripts/backup.sh
```

#### Test-Run 3: Edge Cases
```bash
# 1. Create 10 backups
for i in {1..10}; do
  docker exec test_solr /opt/eledia/scripts/backup.sh
  sleep 5
done

# 2. Check retention (should delete old ones)
docker exec test_solr find /var/solr/backups -name "backup_*" -type d | wc -l
# Should be <= BACKUP_RETENTION_DAYS worth

# 3. Try restore with invalid backup name
docker exec test_solr /opt/eledia/scripts/restore.sh \
  --backup-name invalid_backup_123
# Expected: Clear error message

# 4. Restore from specific backup
docker exec test_solr /opt/eledia/scripts/restore.sh \
  --backup-name $(docker exec test_solr ls -1 /var/solr/backups | head -1)
```

---

### Log Rotation - Voller Test-Zyklus

#### Test-Run 1: Normal Rotation
```bash
# 1. Create 150MB log
docker exec test_solr dd if=/dev/zero of=/var/solr/logs/solr.log bs=1M count=150

# 2. Run rotation
docker exec test_solr /opt/eledia/scripts/log-rotation.sh

# 3. Check results
docker exec test_solr ls -lh /var/solr/logs/
# Expected: solr.log (small) + solr.log.TIMESTAMP.gz (large)
```

#### Test-Run 2: Multiple Rotations
```bash
# Create and rotate 15 times
for i in {1..15}; do
  docker exec test_solr dd if=/dev/zero of=/var/solr/logs/test.log bs=1M count=150
  docker exec test_solr /opt/eledia/scripts/log-rotation.sh
  sleep 1
done

# Check cleanup (should only keep LOG_MAX_FILES=10)
docker exec test_solr ls -1 /var/solr/logs/ | grep "test.log" | wc -l
# Expected: <= 11 (current + 10 rotated)
```

#### Test-Run 3: Compression Test
```bash
# Disable compression
docker exec -e LOG_COMPRESSION=false test_solr dd if=/dev/zero of=/var/solr/logs/uncompressed.log bs=1M count=150
docker exec -e LOG_COMPRESSION=false test_solr /opt/eledia/scripts/log-rotation.sh

# Check no .gz file
docker exec test_solr ls /var/solr/logs/ | grep "uncompressed.log" | grep -v ".gz"
# Should exist
```

---

### Health Checks - Voller Test-Zyklus

#### Test-Run 1: All Modes
```bash
# Liveness
docker exec test_solr bash -c 'HEALTH_CHECK_TYPE=liveness /opt/eledia/scripts/health-check.sh'

# Readiness
docker exec test_solr bash -c 'HEALTH_CHECK_TYPE=readiness /opt/eledia/scripts/health-check.sh'

# Detailed
docker exec test_solr bash -c 'HEALTH_CHECK_TYPE=detailed /opt/eledia/scripts/health-check.sh'
```

#### Test-Run 2: Stress Test
```bash
# Fill heap to trigger memory warning
docker exec test_solr curl -X POST \
  'http://localhost:8983/solr/moodle/update?commit=true' \
  -H 'Content-Type: application/json' \
  -d "$(for i in {1..10000}; do echo {\"id\":\"doc$i\",\"title\":\"Test $i\"}; done | jq -s .)"

# Check health (should show memory warning)
docker exec test_solr bash -c 'HEALTH_CHECK_TYPE=detailed /opt/eledia/scripts/health-check.sh'
```

#### Test-Run 3: Solr Down Scenario
```bash
# Stop Solr
docker exec test_solr /opt/solr/bin/solr stop -all

# Health checks should fail appropriately
docker exec test_solr /opt/eledia/scripts/health-check.sh
# Expected: Exit code != 0, clear error

# Restart
docker-compose restart
```

---

## 📊 ERWARTETE TEST-ERGEBNISSE

### Smoke Tests (alle 17)
```
========================================
Eledia Solr - Smoke Test Suite
========================================

SMOKE TESTS - Feature 1: Backup System
[PASS] backup.sh is executable
[PASS] Backup directory exists
[PASS] Backup script executed successfully
[PASS] Found X backup(s)
[PASS] restore.sh is executable
[PASS] Backup listing works

SMOKE TESTS - Feature 2: Log Rotation
[PASS] log-rotation.sh is executable
[PASS] Log directory exists
[PASS] Log rotation executed successfully

SMOKE TESTS - Feature 3: Health Checks
[PASS] health-check.sh is executable
[PASS] Liveness check passed
[PASS] Readiness check passed
[PASS] Detailed health check passed

DOCKER-NATIVE CHECKS
[PASS] Docker reports container as healthy
[PASS] Container is running
[PASS] Volume exists
[PASS] Solr is accessible

========================================
TEST SUMMARY
========================================

Total Tests: 17
Passed: 17
Failed: 0

✓ ALL TESTS PASSED
```

---

## 🚨 FEHLERBEHANDLUNG

### Backup schlägt fehl
**Symptom**: Backup-Script returned Exit Code != 0
**Diagnose**:
```bash
# Check Solr status
docker exec test_solr curl http://localhost:8983/solr/admin/ping

# Check permissions
docker exec test_solr ls -la /var/solr/backups
docker exec test_solr whoami

# Check disk space
docker exec test_solr df -h /var/solr
```
**Fix**:
- Solr nicht erreichbar → Container neu starten
- Permission denied → Volume-Permissions prüfen
- Disk full → Alte Backups löschen oder Volume vergrößern

---

### Health Check zeigt WARNING
**Symptom**: Exit Code 1, Output zeigt "WARNING"
**Ursache**: Meist Memory oder Disk Nutzung >75%
**Fix**:
```bash
# Check detailed health
docker exec test_solr bash -c 'HEALTH_CHECK_TYPE=detailed /opt/eledia/scripts/health-check.sh'

# If memory issue: Increase heap
# Edit .env: SOLR_HEAP=4g
docker-compose up -d --force-recreate

# If disk issue: Clean up old data
docker exec test_solr rm -rf /var/solr/backups/backup_old_*
```

---

### Log Rotation läuft nicht automatisch
**Symptom**: Logs werden groß, aber nicht rotiert
**Diagnose**:
```bash
# Check if cron is running
docker exec test_solr ps aux | grep cron

# Check crontab
docker exec test_solr crontab -l
```
**Fix**:
```bash
# Manually setup cron
docker exec test_solr /opt/eledia/scripts/setup-cron.sh

# Or run manually via cron
echo "0 * * * * /opt/eledia/scripts/log-rotation.sh" | docker exec -i test_solr crontab -
```

---

## ✅ TEST CHECKLIST

Vor Production-Deploy:

- [ ] Alle 17 Smoke Tests bestanden
- [ ] Backup & Restore manuell getestet (3x)
- [ ] Log Rotation manuell getestet (3x)
- [ ] Health Checks manuell getestet (3x)
- [ ] Docker Health Status: healthy
- [ ] Volume Persistence getestet (Container-Restart)
- [ ] Performance Test (1000+ Dokumente indexiert)
- [ ] Stress Test (Memory-Warning ausgelöst und behoben)
- [ ] Error-Recovery getestet (Solr gestoppt + restarted)
- [ ] Dokumentation gelesen und verstanden

---

**Version**: 1.0.0
**Letzte Aktualisierung**: 06.11.2025
**Status**: Bereit zum Testen
