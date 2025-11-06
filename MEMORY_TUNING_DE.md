# Solr Speicher-Tuning Leitfaden v2.5.0

## Die 50-60% Regel

**WICHTIG**: Solr (Lucene) nutzt MMapDirectory für Indexdateien!

```
┌─────────────────────────────────────────────────┐
│     Gesamter Physischer RAM (z.B. 16GB)        │
├────────────────────────┬────────────────────────┤
│   JVM Heap (50-60%)    │  OS File System Cache  │
│   z.B. 8-10GB          │  (40-50%) z.B. 6-8GB   │
│                        │                        │
│ - Java Objekte         │ - Lucene Index Dateien │
│ - Query Processing     │ - MMapDirectory        │
│ - Caching              │ - Betriebssystem       │
└────────────────────────┴────────────────────────┘
```

### Warum?

- **Lucene-Indexdateien** werden über `mmap()` direkt in den OS-Cache gemappt
- **Zero-Copy** Zugriff ist **VIEL schneller** als Heap-basiertes Lesen
- Wenn Heap = 100% RAM → Lucene Performance bricht massiv ein!

## Konfigurations-Beispiele

### Kleiner Server (4GB RAM)
```bash
SOLR_HEAP_SIZE=2g
SOLR_MEMORY_LIMIT=4g
```

### Mittlerer Server (8GB RAM)
```bash
SOLR_HEAP_SIZE=4g
SOLR_MEMORY_LIMIT=8g
```

### Großer Server (16GB RAM)
```bash
SOLR_HEAP_SIZE=8g
SOLR_MEMORY_LIMIT=16g
```

### Sehr großer Server (32GB RAM)
```bash
SOLR_HEAP_SIZE=16g
SOLR_MEMORY_LIMIT=32g
```

### Massiver Server (64GB RAM)
```bash
SOLR_HEAP_SIZE=31g  # Unter 32GB für compressed OOPs!
SOLR_MEMORY_LIMIT=64g
```

**Wichtig**: Heap > 31GB verliert compressed OOPs! 
→ Bei mehr Bedarf: Mehrere Solr-Instanzen starten!

## Cheat Sheet

| RAM    | JVM Heap | OS Cache | Memory Limit | CPUs |
|--------|----------|----------|--------------|------|
| 4GB    | 2GB      | 2GB      | 4GB          | 2    |
| 8GB    | 4GB      | 4GB      | 8GB          | 4    |
| 16GB   | 8GB      | 8GB      | 16GB         | 8    |
| 32GB   | 16GB     | 16GB     | 32GB         | 16   |
| 64GB   | 31GB     | 33GB     | 64GB         | 32   |

## Monitoring

### 1. Heap-Nutzung prüfen
```bash
curl "http://localhost:8983/solr/admin/info/system?wt=json" | \
  jq '.jvm.memory'
```

### 2. GC Logs analysieren
```bash
# Logs extrahieren
docker cp solr_container:/var/solr/logs/gc.log ./gc.log

# Mit GCEasy analysieren
# → https://gceasy.io/
```

### 3. Container Stats
```bash
docker stats solr_container_name
```

## Symptome & Lösungen

### Zu wenig Heap
**Symptome**:
- Häufige Full GC Events
- Lange GC Pausen (>5s)
- OutOfMemoryError
- Langsame Queries

**Lösung**: Heap erhöhen (max 60% von RAM!)

### Zu viel Heap
**Symptome**:
- Langsame Queries trotz niedriger Last
- Hohes CPU iowait
- OS zeigt wenig freien Speicher
- Häufige Disk I/O

**Lösung**: Heap reduzieren für mehr OS Cache!

### Container OOMKilled
**Symptome**:
```bash
docker ps -a
STATUS: Exited (137) OOMKilled
```

**Formel**:
```
SOLR_MEMORY_LIMIT >= SOLR_HEAP_SIZE * 2
```

**Lösung**:
```bash
# Wenn Heap = 4GB
SOLR_HEAP_SIZE=4g
SOLR_MEMORY_LIMIT=8g  # 2x Heap
```

## Validierung

### Pre-Deployment Checklist
- [ ] `SOLR_HEAP_SIZE` ist 50-60% von `SOLR_MEMORY_LIMIT`
- [ ] `SOLR_MEMORY_LIMIT` ≤ Host RAM
- [ ] `SOLR_HEAP_SIZE` ≤ 31GB (für compressed OOPs)
- [ ] GC Logging aktiviert
- [ ] Monitoring konfiguriert

### Post-Deployment Test
```bash
# 1. Container Memory
docker stats --no-stream | grep solr

# 2. JVM Heap
curl -s "http://localhost:8983/solr/admin/info/system?wt=json" | \
  jq '.jvm.memory.raw'

# 3. GC Verhalten
docker exec solr_container tail -100 /var/solr/logs/gc.log

# 4. Load Test
ab -n 1000 -c 10 "http://localhost:8983/solr/core/select?q=*:*"
```

## G1GC Konfiguration

Unsere docker-compose.yml enthält optimierte G1GC-Einstellungen:

```yaml
SOLR_OPTS: >-
  -XX:+UseG1GC                          # G1 Garbage Collector
  -XX:MaxGCPauseMillis=150              # Max Pause Time
  -XX:InitiatingHeapOccupancyPercent=75 # GC bei 75% starten
  -XX:+AlwaysPreTouch                   # Memory pre-allocate
```

### Anpassungen

**Große Heaps (>16GB)**:
```yaml
-XX:MaxGCPauseMillis=200              # Längere Pausen erlauben
```

**Niedrige Latenz**:
```yaml
-XX:MaxGCPauseMillis=50               # Aggressive Pausenzeit
-XX:InitiatingHeapOccupancyPercent=60 # Früher GC starten
```

**Hoher Durchsatz (Batch Indexing)**:
```yaml
-XX:MaxGCPauseMillis=500              # Längere Pausen OK
-XX:InitiatingHeapOccupancyPercent=85 # GC verzögern
```

## Weiterführende Links

- [Apache Solr JVM Settings](https://solr.apache.org/guide/solr/latest/deployment-guide/jvm-settings.html)
- [Lucene MMapDirectory](https://lucene.apache.org/core/9_9_0/core/org/apache/lucene/store/MMapDirectory.html)
- [G1GC Tuning](https://www.oracle.com/technical-resources/articles/java/g1gc.html)
- [GCEasy](https://gceasy.io/)

---

**Version**: v2.5.0  
**Siehe auch**: README_DE.md, RUNBOOK_DE.md
