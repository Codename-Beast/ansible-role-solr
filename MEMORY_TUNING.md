# Solr Memory Tuning Guide v2.5.0

## Table of Contents
- [Understanding Solr Memory Architecture](#understanding-solr-memory-architecture)
- [The 50-60% Rule](#the-50-60-rule)
- [Configuration Examples](#configuration-examples)
- [Monitoring and Tuning](#monitoring-and-tuning)
- [Troubleshooting](#troubleshooting)
- [Advanced Tuning](#advanced-tuning)

---

## Understanding Solr Memory Architecture

Solr (built on Lucene) uses a **unique memory architecture** that differs from typical Java applications:

### Two Memory Regions

```
┌─────────────────────────────────────────────────┐
│           Total Physical RAM (e.g., 16GB)       │
├────────────────────────┬────────────────────────┤
│   JVM Heap (50-60%)    │  OS File System Cache  │
│   e.g., 8-10GB         │  (40-50%) e.g., 6-8GB  │
│                        │                        │
│ - Java objects         │ - Lucene index files   │
│ - Query processing     │ - MMapDirectory        │
│ - Caching              │ - Operating system     │
└────────────────────────┴────────────────────────┘
```

### Why This Matters

**Lucene uses MMapDirectory** which memory-maps index files directly into the OS file system cache:

1. **JVM Heap** → For application logic, query processing, caching
2. **OS Cache** → For reading Lucene index files (segments, term dictionaries, etc.)

**If you allocate 100% of RAM to JVM heap, Lucene performance degrades severely** because the OS has no memory left for file system caching!

---

## The 50-60% Rule

### Best Practice Formula

```
JVM Heap Size = 50-60% of Total Physical RAM
OS File Cache = 40-50% of Total Physical RAM
```

### Why 50-60%?

- **Lucene index files** are accessed via `mmap()` system call
- OS file system cache provides **zero-copy** access to index data
- This is **MUCH faster** than reading files into JVM heap
- G1GC performs better with smaller heaps (< 16GB ideal)

### Exception: Very Large Heaps

For heaps > 31GB, Java uses **compressed OOPs** (ordinary object pointers):
- If heap ≤ 31GB → Compressed OOPs (more efficient)
- If heap > 31GB → Uncompressed OOPs (higher memory overhead)

**Recommendation**: Keep heap ≤ 31GB. If you need more, use multiple Solr instances.

---

## Configuration Examples

### Example 1: Small Server (4GB RAM)

```bash
# .env configuration
SOLR_HEAP_SIZE=2g
SOLR_MEMORY_LIMIT=4g
SOLR_CPU_LIMIT=2.0
```

**Breakdown**:
- JVM Heap: 2GB (50%)
- OS Cache: 2GB (50%)
- Good for: Development, small indexes (<10GB)

---

### Example 2: Medium Server (8GB RAM)

```bash
# .env configuration
SOLR_HEAP_SIZE=4g
SOLR_MEMORY_LIMIT=8g
SOLR_CPU_LIMIT=4.0
```

**Breakdown**:
- JVM Heap: 4GB (50%)
- OS Cache: 4GB (50%)
- Good for: Production, medium indexes (10-50GB)

---

### Example 3: Large Server (16GB RAM)

```bash
# .env configuration
SOLR_HEAP_SIZE=8g
SOLR_MEMORY_LIMIT=16g
SOLR_CPU_LIMIT=8.0
```

**Breakdown**:
- JVM Heap: 8GB (50%)
- OS Cache: 8GB (50%)
- Good for: Production, large indexes (50-200GB)

---

### Example 4: Very Large Server (32GB RAM)

```bash
# .env configuration
SOLR_HEAP_SIZE=16g
SOLR_MEMORY_LIMIT=32g
SOLR_CPU_LIMIT=16.0
```

**Breakdown**:
- JVM Heap: 16GB (50%)
- OS Cache: 16GB (50%)
- Good for: Production, very large indexes (>200GB)

---

### Example 5: Massive Server (64GB RAM)

```bash
# .env configuration
SOLR_HEAP_SIZE=31g  # Stay under 32GB for compressed OOPs!
SOLR_MEMORY_LIMIT=64g
SOLR_CPU_LIMIT=32.0
```

**Breakdown**:
- JVM Heap: 31GB (~48%) - Maximizes compressed OOPs
- OS Cache: 33GB (52%)
- Good for: Production, massive indexes (>500GB)

**Note**: If you need more than 31GB heap, consider running **multiple Solr instances** instead!

---

## Monitoring and Tuning

### 1. Check Current Memory Usage

```bash
# Container memory stats
docker stats solr_container_name

# JVM heap usage
curl -u admin:password "http://localhost:8983/solr/admin/info/system?wt=json" | \
  jq '.jvm.memory'

# GC statistics
docker exec solr_container_name cat /var/solr/logs/gc.log
```

### 2. Analyze GC Logs

Use these tools to analyze GC logs:

**GCViewer** (Local)
```bash
# Download GC log
docker cp solr_container:/var/solr/logs/gc.log ./gc.log

# Open with GCViewer
java -jar gcviewer.jar ./gc.log
```

**GCEasy** (Online)
- Upload to https://gceasy.io/
- Get automatic recommendations

### 3. Key Metrics to Watch

#### JVM Heap Metrics
```bash
# Check heap usage
curl -u admin:password "http://localhost:8983/solr/admin/metrics?wt=json&group=jvm" | \
  jq '.metrics["solr.jvm"].memory'
```

Monitor:
- **Heap Used After GC** → Should be < 70% of max heap
- **GC Pause Time** → Should be < 1 second
- **GC Frequency** → Full GC should be rare

#### File System Cache Metrics
```bash
# Linux: Check page cache usage
free -h

# Docker stats
docker stats --no-stream solr_container_name
```

### 4. Signs You Need to Adjust Memory

#### Too Little Heap
Symptoms:
- Frequent Full GC events
- Long GC pause times (>5 seconds)
- OutOfMemoryError exceptions
- Slow query performance

Solution: **Increase heap** (but not > 60% of RAM!)

#### Too Much Heap
Symptoms:
- Slow search queries despite low load
- High CPU iowait
- OS showing low free memory
- Cold caches (frequent disk I/O)

Solution: **Reduce heap** to leave more for OS cache

---

## Troubleshooting

### Problem 1: OutOfMemoryError

```
ERROR [Thread-123] OutOfMemoryError: Java heap space
```

**Analysis**:
1. Check current heap: `docker stats`
2. Check GC logs: Look for Full GC frequency
3. Check index size: Is it growing?

**Solutions**:
- Increase heap (up to 60% of RAM)
- Optimize queries (faceting, grouping)
- Add more physical RAM
- Reduce caching configuration

---

### Problem 2: Slow Queries Despite Low Memory Usage

```
Query time: 5000ms (should be <100ms)
JVM Heap: 2GB / 8GB (25% used)
```

**Analysis**:
This often means **insufficient OS file cache**!

**Solutions**:
- Reduce JVM heap to leave more for OS
- Add more physical RAM
- Optimize index (fewer segments)

---

### Problem 3: Container OOMKilled

```
docker ps -a
STATUS: Exited (137) OOMKilled
```

**Analysis**:
Docker memory limit (`SOLR_MEMORY_LIMIT`) is too low.

**Formula**:
```
SOLR_MEMORY_LIMIT >= SOLR_HEAP_SIZE * 2
```

**Why?**:
- JVM heap: `SOLR_HEAP_SIZE`
- JVM non-heap: ~512MB (threads, metaspace, etc.)
- OS buffers: ~256MB
- Safety margin: ~256MB

**Solution**:
```bash
# If heap is 4GB
SOLR_HEAP_SIZE=4g
SOLR_MEMORY_LIMIT=8g  # 2x heap
```

---

## Advanced Tuning

### G1GC Configuration (Already Optimized)

Our docker-compose.yml includes optimized G1GC settings:

```yaml
SOLR_OPTS: >-
  -XX:+UseG1GC                          # Use G1 Garbage Collector
  -XX:+ParallelRefProcEnabled           # Parallel reference processing
  -XX:G1HeapRegionSize=32m              # Region size (auto-calculated)
  -XX:MaxGCPauseMillis=150              # Target max pause time
  -XX:InitiatingHeapOccupancyPercent=75 # Start GC at 75% occupancy
  -XX:+UnlockExperimentalVMOptions      # Enable experimental options
  -XX:+AlwaysPreTouch                   # Pre-touch all memory at startup
```

### When to Adjust G1GC Settings

#### Large Heaps (>16GB)
```yaml
-XX:G1HeapRegionSize=32m              # Increase for large heaps
-XX:MaxGCPauseMillis=200              # Allow slightly longer pauses
```

#### Low-Latency Requirements
```yaml
-XX:MaxGCPauseMillis=50               # Aggressive pause time target
-XX:InitiatingHeapOccupancyPercent=60 # Start GC earlier
```

#### High Throughput (Batch Indexing)
```yaml
-XX:MaxGCPauseMillis=500              # Allow longer pauses
-XX:InitiatingHeapOccupancyPercent=85 # Delay GC for throughput
```

---

### Solr Cache Tuning

Caches consume JVM heap. Adjust based on available heap:

#### Small Heap (2GB)
```xml
<!-- solrconfig.xml -->
<filterCache size="512" initialSize="512" />
<queryResultCache size="512" initialSize="512" />
<documentCache size="512" initialSize="512" />
```

#### Medium Heap (4-8GB)
```xml
<filterCache size="1024" initialSize="512" />
<queryResultCache size="1024" initialSize="512" />
<documentCache size="1024" initialSize="512" />
```

#### Large Heap (16GB+)
```xml
<filterCache size="2048" initialSize="1024" />
<queryResultCache size="2048" initialSize="1024" />
<documentCache size="2048" initialSize="1024" />
```

---

## Quick Reference

### Memory Sizing Cheat Sheet

| Total RAM | JVM Heap | OS Cache | Memory Limit | CPU Cores |
|-----------|----------|----------|--------------|-----------|
| 4GB       | 2GB      | 2GB      | 4GB          | 2         |
| 8GB       | 4GB      | 4GB      | 8GB          | 4         |
| 16GB      | 8GB      | 8GB      | 16GB         | 8         |
| 32GB      | 16GB     | 16GB     | 32GB         | 16        |
| 64GB      | 31GB     | 33GB     | 64GB         | 32        |

### .env Template

```bash
# Calculate based on your server's RAM
TOTAL_RAM_GB=16

# Apply 50% rule
SOLR_HEAP_SIZE=$(($TOTAL_RAM_GB / 2))g
SOLR_MEMORY_LIMIT=${TOTAL_RAM_GB}g

# Example for 16GB server:
SOLR_HEAP_SIZE=8g
SOLR_MEMORY_LIMIT=16g
SOLR_CPU_LIMIT=8.0
```

---

## Validation

### Pre-Deployment Checklist

- [ ] `SOLR_HEAP_SIZE` is 50-60% of `SOLR_MEMORY_LIMIT`
- [ ] `SOLR_MEMORY_LIMIT` matches or is less than host RAM
- [ ] `SOLR_HEAP_SIZE` ≤ 31GB (for compressed OOPs)
- [ ] GC logging enabled (`GC_LOG_OPTS`)
- [ ] Monitoring configured (Prometheus + Grafana)
- [ ] Log rotation configured

### Post-Deployment Validation

```bash
# 1. Check container memory
docker stats --no-stream | grep solr

# 2. Check JVM heap
curl -s "http://localhost:8983/solr/admin/info/system?wt=json" | \
  jq '.jvm.memory.raw'

# 3. Check GC behavior
docker exec solr_container tail -100 /var/solr/logs/gc.log

# 4. Run load test and monitor
ab -n 1000 -c 10 "http://localhost:8983/solr/core/select?q=*:*"
```

---

## Further Reading

- [Apache Solr JVM Settings](https://solr.apache.org/guide/solr/latest/deployment-guide/jvm-settings.html)
- [Lucene MMapDirectory](https://lucene.apache.org/core/9_9_0/core/org/apache/lucene/store/MMapDirectory.html)
- [G1GC Tuning Guide](https://www.oracle.com/technical-resources/articles/java/g1gc.html)
- [GCEasy Analysis Tool](https://gceasy.io/)
- [GCViewer GitHub](https://github.com/chewiebug/GCViewer)

---

**Last Updated**: v2.5.0
**Author**: Automated Configuration
