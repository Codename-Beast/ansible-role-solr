# Solr für Moodle - Docker Edition v2.5.0

**Apache Solr 9.9.0 für Moodle mit Docker Compose**

> 📦 **Eledia Enterprise Lösung** - Eigenständige Docker-Lösung

**Autor**: Codename-Beast (Eledia)
**Version**: 3.4.0

## 🚀 Schnellstart

```bash
# 1. Umgebung initialisieren
make init

# 2. Passwörter in .env anpassen
nano .env

# 3. Konfiguration generieren
make config

# 4. Services starten
make start

# 5. Moodle Core erstellen
make create-core

# 6. Gesundheitsprüfung
make health
```

## 📋 Funktionen v2.5.0

### Kernfunktionen
- ✅ Solr 9.9.0 mit BasicAuth + RBAC
- ✅ Automatische Backups mit Aufbewahrungsmanagement
- ✅ Überwachung: Prometheus + Grafana + Alertmanager
- ✅ Gesundheitsprüfungen mit Wiederholungslogik
- ✅ Netzwerksegmentierung (Frontend/Backend)
- ✅ GC-Logging für Performance-Analyse
- ✅ Log-Rotation für Anwendungsprotokolle
- ✅ Pre-Flight Checks vor Deployment
- ✅ Query Performance Dashboard

### Sicherheit
- 🔒 Double SHA-256 Password Hashing
- 🔒 Drei-Stufen-RBAC (Admin, Support, Kunde)
- 🔒 Netzwerk-Isolation (Frontend/Backend)
- 🔒 Docker Secrets Unterstützung

### Deployment-Modi

```bash
# Minimal (nur Solr)
docker compose up -d

# Mit Monitoring
docker compose --profile monitoring up -d

# Mit Backups
docker compose --profile backup up -d

# Mit Log-Rotation
docker compose --profile logrotate up -d

# Alles zusammen
docker compose --profile monitoring --profile backup --profile logrotate up -d
```

## 📖 Dokumentation

### Betrieb
- **RUNBOOK_DE.md** - Operatives Handbuch für den Betrieb
- **MEMORY_TUNING_DE.md** - Speicher-Tuning Leitfaden

### Entwicklung
- **CHANGELOG.md** - Versionshistorie
- **MONITORING.md** - Monitoring-Konfiguration

## 🔧 Konfiguration

### Speicher-Allokation (50-60% Regel)

Solr nutzt MMapDirectory - OS File System Cache ist **kritisch**!

```bash
# Für 16GB RAM Server:
SOLR_HEAP_SIZE=8g          # 50% für JVM Heap
SOLR_MEMORY_LIMIT=16g      # 50% bleibt für OS Cache
```

Siehe **MEMORY_TUNING_DE.md** für Details!

### GC Logging

```bash
# GC Logs aktiviert in docker-compose.yml
GC_LOG_OPTS: -Xlog:gc*:file=/var/solr/logs/gc.log:...

# Logs analysieren:
docker cp solr_container:/var/solr/logs/gc.log ./
# Upload zu: https://gceasy.io/
```

## 🛠️ Wartung

### Backups

```bash
# Manuelles Backup
make backup

# Automatische Backups (cron)
docker compose --profile backup up -d

# Backup-Aufbewahrung in .env konfigurieren:
BACKUP_RETENTION_DAYS=7
```

### Log-Rotation

```bash
# Log-Rotation Service starten
docker compose --profile logrotate up -d

# Konfiguration: config/logrotate.conf
# - Täglich rotieren
# - 14 Tage aufbewahren
# - Max 100MB pro Datei
```

### Prometheus Retention

```bash
# Berechne optimale Retention
./scripts/calculate-prometheus-retention.sh 50  # 50GB verfügbar

# Ergebnis in .env eintragen:
PROMETHEUS_RETENTION=365d
```

## 🏥 Monitoring

### Grafana Dashboards

```bash
# Monitoring starten
docker compose --profile monitoring up -d

# Grafana öffnen
make grafana

# Standard-Login:
# User: admin
# Pass: admin (in .env ändern!)
```

### Dashboards
1. **Solr Monitoring (Multi-Instance)** - System-Metriken
2. **Query Performance Analysis** - Query-Latenz, Slow Queries, Cache Hit Ratio

### Alerts
- Solr Down
- High Memory Usage (>90%)
- High CPU Usage (>80%)
- Slow Queries (>1s)
- Disk Space Low

## 🔍 Troubleshooting

### Solr startet nicht

```bash
# Logs prüfen
make logs

# Gesundheitsprüfung
make health

# Container-Status
docker compose ps

# Pre-Flight Checks
make preflight
```

### Langsame Queries

1. **GC Logs prüfen**
   ```bash
   docker exec solr cat /var/solr/logs/gc.log
   ```

2. **Heap-Nutzung prüfen**
   ```bash
   curl "http://localhost:8983/solr/admin/info/system?wt=json" | jq '.jvm.memory'
   ```

3. **Speicher neu konfigurieren** (siehe MEMORY_TUNING_DE.md)

### OutOfMemoryError

```bash
# Heap erhöhen (max 60% von RAM!)
SOLR_HEAP_SIZE=8g
SOLR_MEMORY_LIMIT=16g

# Oder: Query-Optimierung, mehr RAM, weniger Caching
```

## 📊 Performance-Tipps

1. **Speicher**: 50-60% Heap, 40-50% OS Cache
2. **GC**: G1GC mit < 1s Pausen
3. **Commits**: autoSoftCommit=1s, autoCommit=15s
4. **Caches**: An Heap-Größe anpassen
5. **Monitoring**: Immer GC Logs aktivieren!

## 🎓 Weitere Ressourcen

- [Apache Solr Dokumentation](https://solr.apache.org/guide/solr/latest/)
- [G1GC Tuning Guide](https://www.oracle.com/technical-resources/articles/java/g1gc.html)
- [GCEasy Analyzer](https://gceasy.io/)

## 📝 Support

- GitHub Issues: [ansible-role-solr/issues](https://github.com/Codename-Beast/ansible-role-solr/issues)
- Dokumentation: Siehe MD-Dateien in diesem Verzeichnis

---

**Version**: v2.5.0  
**Lizenz**: Siehe LICENSE  
**Autor**: Codename-Beast
