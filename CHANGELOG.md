# Changelog

All notable changes to this project will be documented in this file.

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
