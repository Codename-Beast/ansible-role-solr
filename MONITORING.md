# Solr Moodle Docker - Monitoring Guide

Complete guide to the integrated Prometheus + Grafana monitoring stack.

## Overview

The monitoring stack provides comprehensive observability for your Solr deployment:

- **Prometheus**: Metrics collection and storage
- **Solr Exporter**: Exposes Solr metrics in Prometheus format
- **Grafana**: Visualization dashboards
- **Alertmanager**: Alert routing and notifications

## Quick Start

```bash
# Start everything
make start

# Access monitoring
make grafana      # Opens Grafana (default: http://localhost:3000)
make prometheus   # Opens Prometheus (default: http://localhost:9090)
make alertmanager # Opens Alertmanager (default: http://localhost:9093)

# View metrics
make metrics      # Shows current Solr metrics
```

## Architecture

```
┌─────────────┐
│   Solr      │◄──── Users
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ Solr Exporter   │ Port 9854
│ (Prometheus)    │
└──────┬──────────┘
       │ scrape (15s)
       ▼
┌─────────────────┐
│  Prometheus     │ Port 9090
│  + Alert Rules  │
└──────┬──────────┘
       │
       ├──────────►┌─────────────────┐
       │           │  Grafana        │ Port 3000
       │           │  + Dashboards   │
       │           └─────────────────┘
       │
       └──────────►┌─────────────────┐
                   │  Alertmanager   │ Port 9093
                   │  + Notifications│
                   └─────────────────┘
```

## Services

### Solr Exporter

**Port**: 9854
**Metrics**: `/metrics`
**Health**: `/health`

Extracts metrics from Solr Admin API and exposes them in Prometheus format.

**Key Metrics**:
- JVM memory usage
- Garbage collection stats
- Query rates and latencies
- Index sizes
- Cache hit ratios
- Error rates

### Prometheus

**Port**: 9090
**UI**: http://localhost:9090
**Config**: `monitoring/prometheus/prometheus.yml`

**Features**:
- 15-second scrape interval
- 30-day retention (configurable)
- Alert rule evaluation
- Time-series database

**Query Examples**:
```promql
# Heap memory usage
(solr_metrics_jvm_memory_heap_used_bytes / solr_metrics_jvm_memory_heap_max_bytes) * 100

# Query rate
rate(solr_metrics_core_requests_total[5m])

# 95th percentile query time
histogram_quantile(0.95, rate(solr_metrics_core_query_time_seconds_bucket[5m]))
```

### Grafana

**Port**: 3000
**UI**: http://localhost:3000
**Default Credentials**: admin / admin (change immediately!)

**Pre-configured Dashboard**: Solr Moodle Monitoring

**Panels**:
1. **Solr Status** - Instance health
2. **Heap Memory Usage** - JVM memory gauge
3. **Query Rate** - Requests per second
4. **Memory Usage** - Heap used vs max
5. **Query Latency** - p50, p95, p99 percentiles
6. **Document Count** - Total indexed documents
7. **GC Time** - Garbage collection performance
8. **Cache Hit Ratio** - Cache effectiveness
9. **Index Size** - Disk usage
10. **Error Rate** - Query errors

**Accessing Dashboards**:
```bash
make grafana
# OR visit http://localhost:3000
# Login: admin / admin
# Dashboard: "Solr Moodle Monitoring"
```

### Alertmanager

**Port**: 9093
**UI**: http://localhost:9093
**Config**: `monitoring/alertmanager/alertmanager.yml`

**Alert Routing**:
- Critical → Email + Webhook
- Warning → Email
- Info → Webhook

## Alert Rules

### Critical Alerts

| Alert | Condition | Duration | Action |
|-------|-----------|----------|--------|
| **SolrInstanceDown** | Exporter unavailable | 2m | Check Solr container |
| **SolrCriticalMemoryUsage** | Heap > 95% | 2m | Increase heap size |
| **SolrHighErrorRate** | Errors > 0.1/sec | 5m | Check logs |
| **SolrExporterDown** | Exporter down | 1m | Restart exporter |

### Warning Alerts

| Alert | Condition | Duration | Action |
|-------|-----------|----------|--------|
| **SolrHighMemoryUsage** | Heap > 90% | 5m | Monitor, consider scaling |
| **SolrHighGCTime** | GC time > 0.5s/s | 5m | Tune GC or add memory |
| **SolrSlowQueries** | p95 > 2s | 10m | Optimize queries/schema |
| **SolrLowCacheHitRatio** | Hit ratio < 70% | 15m | Increase cache size |

### Info Alerts

| Alert | Condition | Duration | Info |
|-------|-----------|----------|------|
| **SolrIndexSizeGrowingRapidly** | Growth > 10MB/s | 30m | Normal for bulk indexing |
| **SolrNoRecentUpdates** | No updates 1h | 10m | May be normal |

## Configuration

### Prometheus Configuration

**File**: `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'solr-exporter'
    scrape_interval: 10s
    static_configs:
      - targets: ['solr-exporter:9854']
```

**Customize Scrape Interval**:
```yaml
scrape_configs:
  - job_name: 'solr-exporter'
    scrape_interval: 30s  # Change from 10s to 30s
```

### Alert Rules

**File**: `monitoring/prometheus/alerts.yml`

**Add Custom Alert**:
```yaml
- alert: CustomAlert
  expr: your_metric > threshold
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Alert summary"
    description: "Detailed description"
```

### Grafana Customization

**Add Data Source**:
1. Settings → Data Sources → Add
2. Select Prometheus
3. URL: `http://prometheus:9090`
4. Save & Test

**Import Dashboard**:
1. Dashboards → Import
2. Upload JSON or paste ID
3. Select Prometheus data source

### Alertmanager

**File**: `monitoring/alertmanager/alertmanager.yml`

**Email Configuration**:
```yaml
# In .env
SMTP_HOST=smtp.gmail.com:587
SMTP_FROM=alerts@example.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_TLS=true
ALERT_EMAIL_CRITICAL=admin@example.com
```

**Webhook Integration**:
```yaml
# In .env
WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## Metrics Reference

### JVM Metrics

```promql
# Memory
solr_metrics_jvm_memory_heap_used_bytes
solr_metrics_jvm_memory_heap_max_bytes
solr_metrics_jvm_memory_non_heap_used_bytes

# Garbage Collection
solr_metrics_jvm_gc_collections_total
solr_metrics_jvm_gc_time_seconds_total

# Threads
solr_metrics_jvm_threads_current
solr_metrics_jvm_threads_daemon
```

### Solr Core Metrics

```promql
# Requests
solr_metrics_core_requests_total{handler="/select"}
solr_metrics_core_requests_total{handler="/update"}

# Latency
solr_metrics_core_query_time_seconds_bucket
solr_metrics_core_query_time_seconds_sum
solr_metrics_core_query_time_seconds_count

# Documents
solr_metrics_core_num_docs
solr_metrics_core_deleted_docs

# Index
solr_metrics_core_index_size_bytes
solr_metrics_core_segments
```

### Cache Metrics

```promql
# Hits/Misses
solr_metrics_core_cache_hits{cache="queryResultCache"}
solr_metrics_core_cache_misses{cache="queryResultCache"}

# Size
solr_metrics_core_cache_size{cache="queryResultCache"}
solr_metrics_core_cache_evictions{cache="queryResultCache"}
```

## Troubleshooting

### Exporter Not Collecting Metrics

```bash
# Check exporter logs
docker logs default_solr_exporter

# Test manually
curl http://localhost:9854/metrics

# Verify Solr connection
docker exec default_solr_exporter curl -s http://solr:8983/solr/admin/ping
```

### Prometheus Not Scraping

```bash
# Check Prometheus targets
# Visit: http://localhost:9090/targets

# Check Prometheus logs
docker logs default_prometheus

# Verify network connectivity
docker exec default_prometheus wget -O- http://solr-exporter:9854/metrics
```

### Grafana Dashboard Empty

1. Check Prometheus data source connection
2. Verify metrics are being collected: http://localhost:9090/graph
3. Check time range in Grafana (top right)
4. Ensure Solr core exists and has data

### Alerts Not Firing

```bash
# Check alert rules
# Visit: http://localhost:9090/alerts

# View Alertmanager status
# Visit: http://localhost:9093

# Check Alertmanager logs
docker logs default_alertmanager
```

## Performance Tuning

### Reduce Metric Cardinality

```yaml
# prometheus.yml
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'solr_metrics_core_cache_.*'
    action: drop
```

### Increase Scrape Interval

```yaml
# For less critical environments
global:
  scrape_interval: 30s
```

### Reduce Retention

```yaml
# In .env
PROMETHEUS_RETENTION=7d  # Instead of 30d
```

### Limit Dashboard Refresh

In Grafana dashboard settings:
- Set refresh interval to 30s or 1m
- Reduce time range to last 6h or 12h

## Integration Examples

### Slack Notifications

1. Create Slack Incoming Webhook
2. Configure in `.env`:
```bash
WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/YOUR/WEBHOOK
```

3. Test:
```bash
docker restart default_alertmanager
```

### PagerDuty Integration

`alertmanager.yml`:
```yaml
receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}'
```

### Custom Webhook

```python
# webhook-receiver.py
from flask import Flask, request
app = Flask(__name__)

@app.route('/alerts', methods=['POST'])
def receive_alert():
    alerts = request.json
    for alert in alerts['alerts']:
        print(f"Alert: {alert['labels']['alertname']}")
        print(f"Status: {alert['status']}")
    return 'OK', 200

if __name__ == '__main__':
    app.run(port=5001)
```

## Best Practices

1. **Set Up Alerts Early**: Configure email/webhook before going to production
2. **Review Dashboards Daily**: Check for anomalies
3. **Tune Alert Thresholds**: Adjust based on your workload
4. **Regular Backup**: Backup Prometheus data for historical analysis
5. **Monitor the Monitors**: Set up alerts for monitoring stack itself
6. **Secure Access**: Use reverse proxy with authentication for production
7. **Resource Limits**: Set appropriate CPU/memory limits for monitoring services
8. **Data Retention**: Balance retention vs disk space
9. **Document Changes**: Keep track of custom alerts and dashboards
10. **Test Alerts**: Regularly verify alert routing works

## Advanced Usage

### Custom Metrics

Add custom metrics to Solr:
```java
// In Solr plugin
MetricRegistry registry = core.getCoreMetricManager().getRegistry();
Counter customCounter = registry.counter("custom.metric");
customCounter.inc();
```

### Federation

Aggregate metrics from multiple Solr instances:
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'federate'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job="solr-exporter"}'
    static_configs:
      - targets:
        - 'prometheus-central:9090'
```

### Recording Rules

Pre-calculate expensive queries:
```yaml
# prometheus.yml
rule_files:
  - 'recording_rules.yml'

# recording_rules.yml
groups:
  - name: solr
    interval: 30s
    rules:
      - record: job:solr_memory_usage:percent
        expr: (solr_metrics_jvm_memory_heap_used_bytes / solr_metrics_jvm_memory_heap_max_bytes) * 100
```

## Support

For issues or questions:
1. Check logs: `docker logs <container_name>`
2. Review Prometheus targets: http://localhost:9090/targets
3. Verify metrics: http://localhost:9854/metrics
4. Test connectivity between services

---

**Monitoring Stack Version**: 2.1
**Last Updated**: 2024-11-06
