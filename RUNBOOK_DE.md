# Solr Betriebshandbuch v2.5.0

## Notfallkontakte

| Priorität | Beschreibung | SLA |
|-----------|--------------|-----|
| **P1** | Solr komplett down | 15 Min |
| **P2** | Performance-Probleme | 1 Std |
| **P3** | Kleinere Probleme | 1 Tag |

---

## Service-Architektur

```
┌──────────────────────────────────────────────────────────┐
│                   FRONTEND NETWORK                       │
│               (172.20.0.0/24 - Extern)                  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │    Solr    │  │ Health API │  │  Grafana   │        │
│  │   :8983    │  │   :8888    │  │   :3000    │        │
│  └──────┬─────┘  └────────────┘  └──────┬─────┘        │
│         │                                 │              │
└─────────┼─────────────────────────────────┼──────────────┘
          │                                 │
┌─────────┼─────────────────────────────────┼──────────────┐
│         │      BACKEND NETWORK            │              │
│         │  (172.20.1.0/24 - Intern)      │              │
├─────────┴─────────────────────────────────┴──────────────┤
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │ Prometheus │  │Alertmanager│  │  Exporter  │        │
│  │   :9090    │  │   :9093    │  │   :9854    │        │
│  └────────────┘  └────────────┘  └────────────┘        │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Incident Response

### P1: Solr ist down

**Symptome**:
- Health Check fehlgeschlagen
- 502 Bad Gateway Fehler
- Container ist gestoppt

**Sofortmaßnahmen**:
```bash
# 1. Status prüfen
docker compose ps
make health

# 2. Logs prüfen
make logs

# 3. Container neustarten
docker compose restart solr

# 4. Wenn nicht hilft: Neu starten
docker compose down
docker compose up -d
```

**Eskalation**: Wenn nach 15 Min nicht behoben → DevOps Team

---

### P2: Langsame Queries (>1s)

**Symptome**:
- Moodle-Suchfunktion langsam
- Timeouts in Logs
- Hohe Query-Latenz in Grafana

**Diagnose**:
```bash
# 1. Query Performance Dashboard öffnen
# http://localhost:3000 → Solr Dashboard → Query Performance Analysis

# 2. GC Logs prüfen
docker exec solr cat /var/solr/logs/gc.log | tail -100

# 3. Heap-Nutzung prüfen
curl "http://localhost:8983/solr/admin/info/system?wt=json" | jq '.jvm.memory'

# 4. Slow Queries identifizieren
# → Grafana: "Slow Queries (>1s)" Panel
```

**Lösungen**:
1. **Zu viel Heap-Nutzung** (>80%): 
   - Heap erhöhen (max 60% von RAM!)
   - Siehe MEMORY_TUNING_DE.md

2. **Hohe GC-Aktivität**:
   - GC Logs mit GCEasy analysieren: https://gceasy.io/
   - G1GC Parameter anpassen

3. **Cache Miss**:
   - Query Cache Hit Ratio < 50%
   - Warming Queries hinzufügen
   - Cache-Größen erhöhen

**Eskalation**: Wenn nach 1 Std nicht behoben → Performance Team

---

### P3: Disk Space Warnung

**Symptome**:
- Alertmanager Warnung: "Disk Space Low"
- Backup fehlgeschlagen
- Log-Rotation stoppt

**Diagnose**:
```bash
# 1. Disk Space prüfen
df -h

# 2. Größte Verzeichnisse finden
du -sh /var/lib/docker/volumes/* | sort -h | tail -10

# 3. Alte Backups prüfen
ls -lh backups/
```

**Lösungen**:
```bash
# 1. Alte Backups löschen
# (Aufbewahrung in .env anpassen: BACKUP_RETENTION_DAYS)
find backups/ -type f -mtime +30 -delete

# 2. Docker Cleanup
docker system prune -a --volumes

# 3. Log-Rotation manuell ausführen
docker compose --profile logrotate up -d

# 4. Prometheus Retention reduzieren
# → In .env: PROMETHEUS_RETENTION=30d
```

**Eskalation**: Wenn < 10% Disk Space → Sofort Infrastructure Team

---

## Häufige Probleme

### Problem 1: OutOfMemoryError

**Logs**:
```
ERROR [Thread-123] OutOfMemoryError: Java heap space
```

**Lösung**:
```bash
# 1. Heap erhöhen in .env (max 60% von RAM!)
SOLR_HEAP_SIZE=8g
SOLR_MEMORY_LIMIT=16g

# 2. Neu starten
docker compose down
docker compose up -d

# 3. Validieren
docker stats solr
```

---

### Problem 2: Container OOMKilled

**Symptome**:
```bash
docker ps -a
# STATUS: Exited (137)
```

**Ursache**: Docker Memory Limit zu niedrig

**Lösung**:
```bash
# Memory Limit erhöhen (mindestens 2x Heap!)
# In .env:
SOLR_MEMORY_LIMIT=8g  # Wenn Heap = 4g

# Neu starten
docker compose up -d --force-recreate
```

---

### Problem 3: Backup fehlgeschlagen

**Logs**:
```bash
docker logs backup-cron
```

**Häufige Ursachen**:
1. **Disk voll**: Alte Backups löschen
2. **Solr nicht erreichbar**: Netzwerk prüfen
3. **Permissions**: Volume-Rechte prüfen

**Lösung**:
```bash
# 1. Manuelles Backup testen
make backup

# 2. Backup-Service neu starten
docker compose --profile backup up -d --force-recreate

# 3. Logs überwachen
docker logs -f backup-cron
```

---

## Monitoring

### Grafana Dashboards

**Zugriff**: http://localhost:3000

**Dashboards**:
1. **Solr Monitoring** - System-Metriken (CPU, Memory, Disk)
2. **Query Performance** - Query-Latenz, Slow Queries, Cache

**Wichtige Metriken**:
```
solr_jvm_memory_used_bytes        # Heap-Nutzung
solr_metrics_core_query_time_p99  # Query-Latenz (99. Perzentil)
solr_up                            # Service Status
solr_metrics_core_docs             # Anzahl Dokumente
```

### Alerts

| Alert | Schwellwert | Aktion |
|-------|-------------|--------|
| Solr Down | 2 min | P1 Response |
| High Memory | >90% | Heap prüfen |
| High CPU | >80% | Query-Optimierung |
| Slow Queries | >10/sec | Performance-Analyse |
| Disk Space | <10% | Cleanup |

---

## Wartung

### Tägliche Aufgaben (automatisiert)
- ✅ Automatische Backups (2:00 AM, wenn Profile `backup` aktiv)
- ✅ Log-Rotation (2:00 AM, wenn Profile `logrotate` aktiv)
- ✅ Health Checks (alle 30s)

### Wöchentliche Aufgaben
```bash
# 1. Backup-Erfolg prüfen
ls -lh backups/ | tail -10

# 2. Disk Space prüfen
df -h

# 3. GC Logs analysieren
docker cp solr:/var/solr/logs/gc.log ./
# Upload: https://gceasy.io/

# 4. Query Performance Dashboard prüfen
# → Grafana: "Query Performance Analysis"
```

### Monatliche Aufgaben
```bash
# 1. Index optimieren (Segment Merge)
curl -u admin:pass "http://localhost:8983/solr/core/update?optimize=true"

# 2. Security Updates
docker compose pull
docker compose up -d

# 3. Performance Review
# → GC Logs analysieren
# → Heap-Nutzung Trend prüfen
# → Query-Latenz Trend prüfen
```

---

## Backup & Recovery

### Manuelles Backup
```bash
# Backup erstellen
make backup

# Backup-Liste
ls -lh backups/

# Backup-Größe prüfen
du -sh backups/*
```

### Recovery aus Backup
```bash
# 1. Solr stoppen
docker compose stop solr

# 2. Backup-Verzeichnis identifizieren
ls backups/

# 3. Core-Daten ersetzen
# VORSICHT: Löscht aktuelle Daten!
rm -rf data/core/*
cp -r backups/snapshot.YYYYMMDD-HHMMSS/* data/core/

# 4. Permissions korrigieren
chown -R 8983:8983 data/core/

# 5. Solr starten
docker compose start solr

# 6. Validieren
make health
```

---

## Nützliche Befehle

### Service Management
```bash
make start          # Alles starten (mit preflight)
make stop           # Alles stoppen
make restart        # Neustart
make health         # Gesundheitsprüfung
make logs           # Logs anzeigen
```

### Monitoring
```bash
make grafana        # Grafana öffnen
make prometheus     # Prometheus öffnen
make metrics        # Metriken anzeigen
```

### Wartung
```bash
make backup         # Manuelles Backup
make clean          # Container entfernen
make destroy        # ALLES löschen (VORSICHT!)
```

### Diagnose
```bash
# Container-Status
docker compose ps

# Resource-Nutzung
docker stats

# Logs eines Services
docker compose logs -f solr
docker compose logs -f grafana

# In Container einsteigen
docker exec -it solr bash

# Solr Admin API
curl "http://localhost:8983/solr/admin/cores?action=STATUS&wt=json"

# JVM Memory
curl "http://localhost:8983/solr/admin/info/system?wt=json" | jq '.jvm.memory'
```

---

## Eskalationspfade

### Stufe 1: On-Call Engineer (15 Min)
- Service-Neustarts
- Einfache Config-Änderungen
- Backup-Recovery

### Stufe 2: DevOps Team (1 Std)
- Performance-Analyse
- Speicher-Tuning
- Netzwerk-Probleme

### Stufe 3: Development Team (1 Tag)
- Query-Optimierung
- Schema-Änderungen
- Code-Fixes

---

## Pre-Flight Checks

Vor jedem Deployment:

```bash
# Automatische Pre-Flight Checks
make preflight

# Manuelle Validierung
# 1. .env Datei prüfen
cat .env

# 2. Security.json prüfen
cat config/security.json

# 3. Docker Resources prüfen
docker info | grep -A 5 "Memory"

# 4. Disk Space prüfen
df -h
```

---

**Version**: v2.5.0  
**Siehe auch**: README_DE.md, MEMORY_TUNING_DE.md, REVIEWS_v2.5.0_DE.md
