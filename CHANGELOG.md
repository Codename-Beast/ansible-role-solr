# Changelog

All notable changes to this project will be documented in this file.

## [3.2.0] - 2025-11-06

### 🏢 Multi-Tenancy Support (Optional Feature)

**Focus**: Enable hosting multiple isolated search indexes within one Solr instance

### Added

**1. Multi-Tenancy Architecture**
- **Optional feature** for hosting multiple Moodle instances on one server
- Complete isolation through Solr RBAC
- Per-tenant authentication and authorization
- No Moodle installation required - fully standalone

**2. Tenant Management Scripts**
- `scripts/tenant-create.sh` - Create isolated tenant (core + user + RBAC)
  - Generates secure random passwords (32 chars, high entropy)
  - Configures RBAC isolation automatically
  - Validates creation with test queries
  - Saves credentials to `.env.<tenant_id>`
- `scripts/tenant-delete.sh` - Delete tenant with optional backup
  - Optional backup before deletion
  - Removes core, user, and RBAC configuration
  - Archives credentials file
  - Confirmation prompt required
- `scripts/tenant-list.sh` - List all tenants with statistics
  - Shows tenant ID, core name, user account, document count, size, status
  - Detailed view with `--detailed` flag
  - Connection test for each tenant
- `scripts/tenant-backup.sh` - Backup single or all tenants
  - Per-tenant backup with Solr snapshots
  - Bulk backup with `--all` flag
  - List backups with `--list`
  - Clean old backups with `--clean`

**3. Documentation**
- `MULTI_TENANCY.md` - Comprehensive English guide
  - Architecture diagrams (single vs multi-tenant)
  - Security isolation details
  - Tenant management instructions
  - Naming conventions
  - Migration guide (single → multi)
  - Best practices (capacity planning, naming, backups)
  - Troubleshooting section
- `MULTI_TENANCY_DE.md` - Complete German translation

**4. Makefile Integration**
- `make tenant-create TENANT=<id>` - Create new tenant
- `make tenant-delete TENANT=<id> [BACKUP=true]` - Delete tenant
- `make tenant-list` - List all tenants
- `make tenant-backup TENANT=<id>` - Backup single tenant
- `make tenant-backup-all` - Backup all tenants

**5. Multi-Tenant Integration Tests**
- `tests/multi-tenant-test.sh` - Comprehensive test suite (30+ tests)
- Test categories:
  - Tenant creation (8 tests)
  - Tenant access (4 tests)
  - Security isolation (4 tests)
  - Data isolation (4 tests)
  - Tenant management (8 tests)
- Auto-cleanup of test tenants
- Validates RBAC enforcement

### Security Isolation

**RBAC Enforcement**:
- ✅ Each tenant has dedicated Solr core
- ✅ Each tenant has unique user account
- ✅ Tenants CANNOT access other tenants' cores (403 Forbidden)
- ✅ Tenants CANNOT perform admin operations
- ✅ Admin user retains full access for management
- ✅ Passwords use double SHA-256 hashing (Ansible-compatible)

**Tested Security**:
- Cross-tenant query attempts blocked (HTTP 403)
- Admin API access denied for tenants
- Core creation attempts denied for tenants
- Data isolation verified (tenant1 cannot see tenant2's documents)

### Use Cases

✅ **When to use Multi-Tenancy**:
- Multiple Moodle instances on one server
- Development/Staging/Production environments
- Departmental isolation
- Cost optimization (vs. multiple Solr containers)
- Centralized management

❌ **When to use Single-Tenant (Default)**:
- One application needs search
- Maximum container-level isolation needed
- Minimal complexity desired

### Naming Conventions

- **Cores**: `moodle_<tenant_id>` (e.g., `moodle_tenant1`)
- **Users**: `<tenant_id>_customer` (e.g., `tenant1_customer`)
- **Credentials**: `.env.<tenant_id>` (e.g., `.env.tenant1`)

### Usage Examples

```bash
# Create a tenant
make tenant-create TENANT=prod

# Output:
# ✅ Tenant 'prod' created successfully!
# 📋 Connection Details:
#    Core:     moodle_prod
#    User:     prod_customer
#    Password: <random-32-char-password>
#    URL:      http://localhost:8983/solr/moodle_prod
# 🔐 Credentials saved to: .env.prod

# List all tenants
make tenant-list

# Backup a tenant
make tenant-backup TENANT=prod

# Delete a tenant (with backup)
make tenant-delete TENANT=prod BACKUP=true

# Backup all tenants
make tenant-backup-all
```

### Moodle Configuration

```php
// In config.php for tenant:
$CFG->solr_server_hostname = 'localhost';
$CFG->solr_server_port = '8983';
$CFG->solr_indexname = 'moodle_prod';  // Tenant-specific core
$CFG->solr_server_username = 'prod_customer';
$CFG->solr_server_password = '<from .env.prod>';
```

### Impact

- **Resource Efficiency**: 1 Solr container hosts multiple tenants (vs. N containers)
- **Cost Reduction**: Lower memory/CPU overhead
- **Centralized Management**: Single monitoring/backup stack
- **Security**: RBAC-enforced isolation at Solr level
- **Flexibility**: Can mix single-tenant and multi-tenant deployments

### Design Decision

Multi-tenancy was implemented as **user-requested feature** for legitimate use case:
- ✅ Multiple Moodle instances on one server (real-world scenario)
- ✅ Full Docker version works **without Moodle dependency** (standalone requirement met)
- ✅ Optional feature (default remains single-tenant)

### Stats

- **4 new scripts** (tenant-create, tenant-delete, tenant-list, tenant-backup)
- **2 new docs** (MULTI_TENANCY.md, MULTI_TENANCY_DE.md)
- **5 new Makefile targets** (tenant-*)
- **1 new test suite** (multi-tenant-test.sh with 30+ tests)
- **~1,500 lines of code** (tenant management)

---

**Version**: 3.2.0
**Focus**: Multi-Tenancy (Optional)
**Requirement**: Standalone (no Moodle dependency) ✅

---

## [3.0.0] - 2025-11-06

### 🎉 Major Milestone Release

Production-ready standalone Docker solution with comprehensive features.

### Complete Feature Set
- ✅ Solr 9.9.0 + BasicAuth + RBAC + Ansible-compatible hashing
- ✅ Monitoring (Prometheus + Grafana + Alertmanager)
- ✅ Query Performance Dashboard (6 panels)
- ✅ Health Dashboard Script
- ✅ Integration Test Suite (40+ tests)
- ✅ Pre-Flight Checks
- ✅ Log Rotation
- ✅ GC Logging
- ✅ Network Segmentation
- ✅ Bilingual Docs (EN/DE)

---

## [2.6.0] - Dashboard & Tests
## [2.5.0] - P1 Features (Log Rotation, GC, Pre-Flight, Memory Docs)
## [2.4.0] - P2 Features (Network Segmentation, Grafana Templating, Runbook)
## [2.3.1] - Ansible-Compatible Hashing (Double SHA-256)
## [2.3.0] - Production Features
## [2.2.0] - Monitoring with Profiles
## [2.1.0] - Initial Monitoring
## [2.0.0] - Docker Standalone

See full changelog in documentation.

**Last Updated**: v3.0.0 - 2025-11-06

---

## [3.1.0] - 2025-11-06

### 🔒 Security & Quality Improvements

**Focus**: CI/CD automation, security scanning, and performance benchmarking

### Added

**1. GitHub Actions CI/CD Pipeline**
- `.github/workflows/ci.yml` - Comprehensive CI/CD
- 7 jobs: config validation, script validation, Python validation, security scan, docs check, integration test validation, preflight validation
- Runs on push/PR to main, master, and claude/** branches
- Auto-validates: YAML, shellcheck, Python syntax, documentation
- Security scanning with Trivy integrated

**2. Security Scanning with Trivy**
- `scripts/security-scan.sh` - Interactive security scanner
- Scans: Docker Compose config, filesystem, Docker images, secrets
- Generates JSON and SARIF reports
- Menu-driven or `--all` for full scan
- Auto-installs Trivy if missing
- `make security-scan` command

**3. Performance Benchmark Script**
- `scripts/benchmark.sh` - Baseline performance metrics
- Benchmarks: ping, simple query, facet query, search query
- Measures: JVM memory, core statistics, query latency
- Generates timestamped reports in `benchmark-results/`
- Configurable: warmup queries, benchmark queries, concurrent users
- `make benchmark` command

**4. Project Quality**
- `.gitignore` - Ignores security-reports/, benchmark-results/, data/, logs/
- Makefile updated with `security-scan` and `benchmark` targets
- Markdown link checking configuration

### Purpose

These improvements address **valid feedback** while ignoring **over-engineering suggestions**:

✅ **Implemented** (makes sense):
- CI/CD Pipeline (GitHub Actions) - Automates validation
- Security Scanning (Trivy) - Identifies vulnerabilities
- Performance Benchmarks - Baseline for comparisons

❌ **Rejected** (not relevant for standalone Docker):
- Kubernetes Support - Contradicts "standalone" project goal
- Docker Compose splitting - Current profile solution is better
- Multi-tenancy - Not required
- Distributed Tracing - Overkill for single-node

### Usage

```bash
# CI/CD (automatic on git push)
git push

# Security scan (interactive)
make security-scan

# Security scan (full, non-interactive)
./scripts/security-scan.sh --all

# Performance benchmark
make benchmark
```

### Impact

- **CI/CD**: Prevents broken code from merging
- **Security**: Identifies vulnerabilities in Docker images and configs
- **Benchmarks**: Detects performance regressions over time

### Stats

- **3 new scripts** (security-scan.sh, benchmark.sh, CI workflow)
- **2 new Makefile targets** (security-scan, benchmark)
- **7 CI/CD jobs** (comprehensive validation)
- **4+ scan types** (config, filesystem, images, secrets)

---

**Version**: 3.1.0
**Focus**: Quality, Security, Automation
**Feedback Addressed**: Valid suggestions only (no over-engineering)
