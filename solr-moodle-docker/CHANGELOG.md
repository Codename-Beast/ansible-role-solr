# Changelog

All notable changes to the Solr Moodle Docker standalone edition.

## [2.1.0] - 2024-11-06

### Added - Complete Monitoring Stack
- **Prometheus** integration for metrics collection
  - 15-second scrape interval
  - 30-day retention (configurable)
  - Alert rule evaluation
  - Comprehensive scraping configuration
- **Solr Prometheus Exporter** service
  - Native Solr 9.9.0 exporter
  - Real-time metrics exposition
  - JVM, query, cache, and index metrics
- **Grafana** dashboards with pre-configured panels
  - Solr status and health
  - Memory usage (heap, non-heap)
  - Query rates and latencies (p50, p95, p99)
  - Document counts
  - GC performance metrics
  - Cache hit ratios
  - Index sizes
  - Error rates
  - Auto-provisioned data source
- **Alertmanager** for alert routing
  - Email notifications
  - Webhook integrations
  - Critical, warning, and info severity levels
  - Alert inhibition rules
- **14 Pre-configured Alert Rules**:
  - SolrInstanceDown
  - SolrHighMemoryUsage (>90%)
  - SolrCriticalMemoryUsage (>95%)
  - SolrHighGCTime
  - SolrQueryRateDropped
  - SolrHighErrorRate
  - SolrSlowQueries
  - SolrLowCacheHitRatio
  - SolrIndexSizeGrowingRapidly
  - SolrNoRecentUpdates
  - SolrExporterDown
  - PrometheusDown
  - And more...
- **MONITORING.md** - Complete monitoring guide (700+ lines)
- **Makefile extensions** for monitoring:
  - `make monitoring-up` - Start monitoring stack
  - `make monitoring-down` - Stop monitoring stack
  - `make grafana` - Open Grafana dashboard
  - `make prometheus` - Open Prometheus UI
  - `make alertmanager` - Open Alertmanager UI
  - `make metrics` - Show current metrics

### Changed - Optimizations
- **Relocated stopwords** to dedicated `/lang` directory
  - Better organization
  - Cleaner separation of concerns
  - Easier maintenance
- **Optimized docker-compose.yml**:
  - CPU limits and reservations
  - Improved healthchecks (3 retries, faster intervals)
  - Named volumes for better management
  - Named network with custom bridge
  - Optimized SOLR_OPTS with G1GC tuning
  - Reduced init container output verbosity
  - Restart policies tuned
- **Enhanced .env configuration**:
  - Added monitoring ports and credentials
  - CPU limit settings
  - SMTP configuration for alerts
  - Webhook URLs for integrations
  - All monitoring services configurable
- **Improved scripts**:
  - start.sh now shows monitoring URLs
  - generate-config.sh optimized
  - Better error handling

### Technical Details
- Added 5 monitoring services (exporter, prometheus, grafana, alertmanager)
- Created 4 persistent volumes for monitoring data
- 6 new configuration files in monitoring/ directory
- Pre-configured Grafana dashboard with 10 panels
- Comprehensive Prometheus scraping and alert rules
- Email and webhook alert routing
- Docker healthchecks for all monitoring services

### Infrastructure
- Monitoring stack isolated on same Docker network
- All services communicate via service names
- Prometheus scrapes exporter every 10 seconds
- Alert evaluation every 15 seconds
- Grafana auto-provisioned with data source and dashboard

## [2.0.0] - 2024-11-06

### Added
- Complete standalone Docker setup
- Docker Compose v2 configuration with init container
- Automated configuration generation
- Password hashing utility (Python)
- Management scripts:
  - start.sh - Start services
  - stop.sh - Stop services
  - health.sh - Health monitoring
  - backup.sh - Automated backups
  - create-core.sh - Core creation
  - logs.sh - Log viewing
  - generate-config.sh - Config generation
- Makefile with convenient commands
- Comprehensive README with examples
- Moodle schema (4.1 - 5.0.x compatible)
- Solr 9.9.0 configuration optimized for Moodle
- BasicAuth security with 3 roles (admin, support, customer)
- Health check endpoints (unauthenticated)
- Automated backup with retention management
- Multi-language stopwords (EN, DE)
- Directory structure for data, backups, logs

### Features
- Zero-downtime updates
- Configuration validation (JSON, XML)
- Docker healthcheck integration
- Volume management
- Network isolation
- Memory limits
- Automated config backup
- Role-based access control

### Security
- SHA-256 password hashing
- BasicAuth enforcement
- Public health endpoints
- Protected admin operations
- Credential management via .env

## [1.0.0] - Initial Ansible Role
- Ansible-based deployment
- Not included in standalone edition
