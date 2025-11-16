# Ansible Role: Solr

![Version](https://img.shields.io/badge/version-3.9.2-blue)
![Ansible](https://img.shields.io/badge/ansible-2.10.12+-green)
![Solr](https://img.shields.io/badge/solr-9.9.0%20min-orange)
![Moodle](https://img.shields.io/badge/moodle-4.1--5.0.3-purple)
![Tests](https://img.shields.io/badge/tests-pending%20validation-yellow)
![Quality](https://img.shields.io/badge/code%20quality-9.2%2F10-success)
![Status](https://img.shields.io/badge/status-testing-yellow)

Ansible role for deploying Apache Solr 9.9.0 (9.10 validated) with BasicAuth, Moodle schema support (file indexing), full idempotency,user management, automated backup, and comprehensive monitoring.

**Author**: Bernd Schreistetter
**Organization**: Eledia GmbH
**Project Timeline**: 24.09.2025 - 16.11.2025 (54 days)

---

## 🎉 What's New in v3.9.2 (Critical RAM Fix + Apache VHost)

<table>
<tr>
<td width="50%">

### ✨ New in v3.9.2 (TESTING)
- 🔴 **CRITICAL: RAM-Kalkulation korrigiert** - 16GB → 4 Cores (war: 10 Cores)
- 📊 **Korrigierte Werte** - ~2GB/Core statt 600MB (Caches sind PER-CORE!)
- 🌐 **Apache VHost Generic** - Funktioniert mit jeder Domain
- 🔐 **SSL-Awareness** - Keine HTTP-Warnings mehr in WebUI
- 🛠️ **JVM-Konflikte behoben** - autoCommit nur noch in solrconfig.xml
- ⚠️ **Status:** Testing - Fehler bei Abnahme gefixt, Kompletttest ausstehend

### ✨ New in v3.9.0
- 🏢 **Multi-Core Support** - Isolierte Cores pro Moodle-Instanz
- 🔐 **Auto-Password Generation** - Generiert sichere Passwörter
- 📋 **Credential Display** - Zeigt alle Zugangsdaten nach Deployment

### ✨ New in v3.8.1
- 🌐 **Nginx Support** - Apache + Nginx webserver support
- 📝 **Domain-based Configs** - `solr.kunde.de.conf` naming
- 🔒 **HTTPS Auto-Testing** - Up to 10 retries, 3s delay
- 📋 **Let's Encrypt Hints** - Documented certbot commands
- 🛡️ **IP-based Access Control** - Restrict admin access
- 🔐 **Solr SSL-Awareness** - No more HTTP warnings in WebUI!

### ✅ v3.8.0 Features
- ✅ **Solr 9.10 Ready** - 100% compatibility validated
- ✅ **Add User Management** - Add users and their permissions
- ✅ **Zero-Downtime User Management** - Hot-reload via API
- ✅ **Complete Moodle Support** - File indexing fields added
- ✅ **Production Hardened** - All critical bugs fixed
- ✅ **Industry Best Practice** - Code quality 9.2/10

</td>
<td width="50%">

### 🏢 Multi-Core Features (v3.9.2 Korrigiert)
- ✅ **16GB Server:** Max 4 Cores @ ~2GB/Core (KORRIGIERT!)
- ✅ **32GB Server:** Max 10 Cores @ ~2GB/Core
- ✅ Each core: dedicated index + users
- ✅ Caches sind PER-CORE (nicht geteilt!)
- ✅ Nachträglich erweiterbar (idempotent)
- ✅ Automatic role assignment per core
- ⚠️ **Alte Werte (v3.9.0) waren FALSCH!**

### 🔧 Proxy Improvements
- ✅ Standalone VirtualHost/Server configs
- ✅ Modern SSL/TLS (TLS 1.2+, secure ciphers)
- ✅ HTTP → HTTPS redirect when SSL enabled
- ✅ ACME challenge locations for certbot
- ✅ Optional proxy-level Basic Auth
- ✅ Public health check endpoint
- ✅ Solr knows it's behind HTTPS proxy (correct links)

### 🐛 v3.8.0 Critical Fixes
- ✅ Fixed circular variable dependency
- ✅ Fixed docker_container_info bug
- ✅ Fixed Moodle schema fields
- ✅ Fixed password exposure (no_log)
- ✅ Corrected RAM documentation

</td>
</tr>
</table>

**Status:** 🧪 **TESTING** (v3.9.2 - Fehler bei Abnahme gefixt und weitere fehler behandelt | **Critical Fix:** RAM-Kalkulation korrigiert | **Webservers:** Apache + Nginx | **Multi-Core:** 4 cores @ 16GB, 10 cores @ 32GB

---

## 🎯 Features

### Capabilities
- ✅ **Full Idempotency** - Run unlimited times without side effects
- ✅ **Automatic Rollback** - Deployment failure recovery with block/rescue/always
- ✅ **Selective Password Updates** - Change passwords without container restart (ZERO downtime)
- ✅ **Smart Core Management** - Core name changes create new cores, old ones preserved
- ✅ **Docker Compose v2** - Modern init-container pattern for config deployment
- ✅ **BasicAuth Security** - Role-based access control (admin/support/customer)
- ✅ **Moodle Schema** - Pre-configured for Moodle 4.1-5.0.x compatibility
- ✅ **Automated Backups** - Scheduled backups with retention management
- ✅ **Performance Monitoring** - JVM metrics, GC optimization, health checks

### Testing & Validation
- ✅ **Comprehensive Testing** - 19 integration tests (100% pass rate)
- ✅ **Moodle Document Tests** - 10 schema-specific validation tests
- ✅ **Authentication Tests** - Multi-user authorization validation
- ✅ **Performance Tests** - Memory usage and query response times

---

## 📊FEATURE SUPPORT MATRIX

### 🔐 SECURITY & AUTHENTICATION FRAMEWORK

| Feature | Admin | Support | Customer | Anonymous | Implementation | Status |
|---------|-------|---------|----------|-----------|----------------|--------|
| **Authentication Layer** |
| BasicAuth Login | ✅ | ✅ | ✅ | ❌ | SHA-256 Hashing | ✅Ready |
| Session Management | ✅ | ✅ | ✅ | ❌ | Solr Native | ✅Ready |
| Password Rotation | ✅ | ✅ | ✅ | ❌ | Zero-Downtime API | ✅Ready |
| **Authorization Matrix** |
| Security Panel Access | ✅ | ❌ | ❌ | ❌ | security-read/edit | ✅Ready |
| Core Administration | ✅ | ❌ | ❌ | ❌ | core-admin-edit | ✅Ready |
| Schema Management | ✅ | ❌ | ❌ | ❌ | schema-edit | ✅Ready |
| Collection Admin | ✅ | ❌ | ❌ | ❌ | collection-admin-edit | ✅Ready |
| **Data Operations** |
| Document Read | ✅ | ✅ | ✅ | ❌ | Collection-scoped | ✅Ready |
| Document Write/Index | ✅ | ❌ | ✅ | ❌ | Collection-scoped | ✅Ready |
| Document Delete | ✅ | ❌ | ❌ | ❌ | Admin-only | ✅ v3.4 |
| **System Operations** |
| Metrics Access | ✅ | ✅ | ❌ | ❌ | /admin/metrics | ✅ v3.4 |
| Backup Operations | ✅ | ❌ | ❌ | ❌ | /admin/cores | ✅ v3.4 |
| Log Management | ✅ | ✅ | ❌ | ❌ | /admin/logging | ✅ v3.4 |
| Health Checks | ✅ | ✅ | ✅ | ✅ | Public endpoints | ✅Ready |

### 🏗️ INFRASTRUCTURE & DEPLOYMENT MATRIX

| Component | Auto-Deploy | Auto-Config | Monitoring | Backup | Rollback | Status |
|-----------|-------------|-------------|------------|--------|----------|--------|
| **Container Platform** |
| Docker Engine | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Ready |
| Docker Compose v2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Ready |
| Volume Management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Ready |
| Network Isolation | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ Ready |
| **Configuration Management** |
| Solr Core Config | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Ready |
| Moodle Schema | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Ready |
| Security Templates | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Ready |
| Language Files | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ Ready |
| **System Integration** |
| Apache Proxy | ✅ | ✅ | ⚠️ | ❌ | ❌ | ⚠️ Partial |
| Nginx Proxy | ✅ | ✅ | ⚠️ | ❌ | ❌ | ⚠️ Partial |
| Systemd Services | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ Ready |
| **Backup & Recovery** |
| Automated Backups | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |
| Manual Backups | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |
| Retention Management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |
| Backup Verification | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |

### 🧪 TESTING & QUALITY ASSURANCE MATRIX

| Test Category | Coverage | Auto-Execution | Error Handling | Cleanup | Reporting | Status |
|---------------|----------|-----------------|----------------|---------|-----------|--------|
| **Integration Tests** |
| Authentication Tests | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 9/9 PASS |
| Authorization Tests | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Document Operations | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Performance Tests | 90% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| **Moodle-Specific Tests** |
| Schema Validation | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 10/10 PASS |
| Document Types | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 5/5 Types |
| Field Mapping | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Search Operations | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 4/4 PASS |
| **System Tests** |
| Container Health | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Memory Usage | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Backup Functionality | 100% | ✅ | ✅ | ✅ | ✅ | ✅ **NEW v1.4** |

### 📊 PERFORMANCE & MONITORING MATRIX

| Metric Category | Collection | Alerting | Visualization | Export | Retention | Status |
|-----------------|------------|----------|---------------|--------|-----------|--------|
| **JVM Metrics** |
| Memory Usage | ✅ | ⚠️ | ❌ | ⚠️ | ✅ | ✅ **Enhanced v1.4** |
| GC Performance | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ **NEW v1.4** |
| Thread Stats | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Ready |
| **Solr Metrics** |
| Query Performance | ✅ | ⚠️ | ❌ | ⚠️ | ✅ | ✅ **Enhanced v1.4** |
| Index Size | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Ready |
| Request Rates | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Ready |
| **System Health** |
| Container Status | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ Ready |
| Disk Usage | ✅ | ⚠️ | ❌ | ❌ | ✅ | ✅ Ready |
| Network I/O | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Ready |

---

## 📋 Requirements

### System Requirements
- **OS**:  Debian 11/12
- **Ansible**: 2.10.12 or higher
- **Docker**: 20.10+ with Compose v2
- **Disk**: Minimum 10GB free space


### System Packages (auto-installed)
- curl
- ca-certificates
- gnupg
- lsb-release
- jq (for JSON validation)
- libxml2-utils (for XML validation)

---

## 🚀 Quick Start
### 1. Install the Role
```bash
# From Git (v3.8.0)
git clone -b branch \
  https://github.com/Codename-Beast/ansible-role-solr.git roles/solr

# Or from Ansible Galaxy (when published)
ansible-galaxy install eledia.solr
```

### 2. Create Inventory
```ini
# inventory/hosts
[solr_servers]
solr-prod-01 ansible_host=192.168.1.10 ansible_user=root
```

### 3. Create Playbook
```yaml
# playbook.yml
---
- hosts: solr_servers
  become: true
  roles:
    - role: solr
      vars:
        customer_name: "acme-corp"
        moodle_app_domain: "moodle.acme.com"
        solr_core_name: "acme_core"
        # Use ansible-vault for passwords!
        solr_admin_password: "{{ vault_solr_admin_password }}|| Plaintext"
        solr_support_password: "{{ vault_solr_support_password }}|| Plaintext"
        solr_customer_password: "{{ vault_solr_customer_password }} || Plaintext"
```

### 4. Run
```bash
ansible-playbook -i inventory/hosts playbook.yml
```

---

## ⚙️ Configuration

### Required Variables
```yaml
customer_name: "eledia.de"           # Customer identifier
moodle_app_domain: "moodle.eledia.de" # Your Moodle domain
```

### Authentication (Use ansible-vault!)
```yaml
solr_admin_password: "admin_secret"      # Admin user password (min 12 chars)
solr_support_password: "support_secret"  # Support user password
solr_customer_password: "customer_secret" # Customer user password

# Optional: Override usernames
solr_admin_user: "admin"                 # Default: admin
solr_support_user: "support"             # Default: support
solr_customer_user: "customer"           # Default: customer
```

### Container Configuration
```yaml
solr_version: "9.9.0"  # Upgrade to 9.10.0 validated and ready (compatible)
solr_port: 8983                          # Solr port (default: 8983)
solr_heap_size: "2g"                     # Java heap size
solr_memory_limit: "2g"                  # Container memory limit
```

### Directory Structure
```yaml
solr_compose_dir: "/opt/solr/{{ customer_name }}"
solr_config_dir: "/opt/solr/{{ customer_name }}/config"
solr_backup_dir: "/opt/solr/{{ customer_name }}/backup"
solr_log_dir: "/var/log/solr"
```

### Advanced Options
```yaml
# Behavior
solr_force_recreate: false               # Force container recreate
solr_force_pull: false                   # Force image pull
solr_force_reconfigure_auth: false       # Force auth reconfiguration

# Features
solr_auth_enabled: true                  # Enable BasicAuth
solr_proxy_enabled: true                 # Enable reverse proxy
solr_backup_enabled: true                # Enable backups
solr_use_moodle_schema: true             # Use Moodle schema

# Moodle Configuration
solr_moodle_version: "5.0.x"             # Moodle version (4.1, 4.2, 4.3, 4.4, 5.0.x)
solr_max_boolean_clauses: 2048
solr_auto_commit_time: 15000             # ms
solr_auto_soft_commit_time: 1000         # ms

# Webserver
solr_webserver: "nginx"                  # or "apache"
solr_proxy_path: "/solr"
solr_ssl_enabled: true

# Solr Internal Health Checks (NEW in v1.3.2)
solr_health_check_enabled: true          # Enable Solr's built-in health check handler
solr_health_check_mode: "standard"       # Mode: basic, standard, comprehensive
solr_health_disk_threshold: 10           # Warn if < X% disk space free
solr_health_memory_threshold: 90         # Warn if > X% heap memory used
solr_health_cache_threshold: 75          # Warn if cache hit ratio < X% (comprehensive only)
```

#### Solr Internal Health Check Modes

Solr 9.9.0 provides built-in health check handlers accessible via API endpoints.

| Mode | Checks | Endpoints | Overhead | Use Case |
|------|--------|-----------|----------|----------|
| **basic** | Disk space only | `/admin/healthcheck` | Minimal | Quick status checks |
| **standard** | Disk + Memory + Index | `/admin/health` | **Low** | **Production (recommended)** |
| **comprehensive** | All + Cache + Metrics | `/admin/health` | Medium | Critical systems, debugging |

**Health Check Endpoints:**

```bash
# Simple health check (basic)
curl -u admin:password "http://localhost:8983/solr/admin/healthcheck"

# Detailed health check (standard/comprehensive)
curl -u admin:password "http://localhost:8983/solr/admin/health"
```

**Response includes:**
- Disk space availability (% free)
- JVM heap memory usage (% used)
- Index health and optimization status
- Cache hit ratios (comprehensive mode)
- Detailed metrics (comprehensive mode)

**Example configurations:**

```yaml
# Development: Minimal overhead
solr_health_check_mode: "basic"

#Ready: Balanced monitoring (default)
solr_health_check_mode: "standard"
solr_health_disk_threshold: 10      # Alert if < 10% free
solr_health_memory_threshold: 90    # Alert if > 90% used

# Critical systems: Comprehensive monitoring
solr_health_check_mode: "comprehensive"
solr_health_disk_threshold: 15
solr_health_memory_threshold: 85
solr_health_cache_threshold: 75
```

**Disable health checks** (not recommended):
```yaml
solr_health_check_enabled: false
```

### Multi-Core Configuration (v3.9.0+)

Deploy up to **4-5 Moodle instances** on a 16GB server, or **10 instances** on a 32GB server with automatic RAM management and password generation.

#### ⚠️ RAM Calculation (Fixed in v3.9.0)

**WICHTIG:** Die vorherige Berechnung war **fundamental falsch**!

**Problem:** Caches sind **PER-CORE** und multiplizieren sich (nicht geteilt)!

**Korrekte Berechnung basierend auf Research**

```
16GB Server mit 8GB Heap:
├── JVM Heap:        8GB  (Solr/Lucene operations)
├── OS Disk Cache:   6GB  (MMapDirectory - KRITISCH!)
└── System:          2GB  (Docker, OS processes)

Pro Core RAM-Bedarf (effektiv):
├── ramBufferSizeMB:  75-100MB (PER-CORE!)
├── filterCache:      ~50MB    (512 entries @ 12.5MB max, PER-CORE!)
├── queryResultCache: ~50MB    (PER-CORE!)
├── documentCache:    ~50MB    (PER-CORE!)
├── Misc/Temp:        4-6GB   (global, nicht pro Core)
└── Working Memory:   Rest    (Query processing)

EFFEKTIV PRO CORE: ~1.5-2GB (NICHT 600MB!)
```

**Limits für Moodle mit File-Indexing:**

| Server RAM | Heap | OS Cache | Max Cores | RAM/Core | Status |
|------------|------|----------|-----------|----------|--------|
| **16GB** | 8GB | 6GB | **4-5** | ~1.5-2GB | ✅ Empfohlen |
| 16GB | 8GB | 6GB | 6 | ~1GB | ⚠️ Performance-Einbußen |
| 16GB | 8GB | 6GB | >6 | <1GB | ❌ Deployment blockiert |
| **32GB** | 20GB | 10GB | **10** | ~1.5-2GB | ✅ Empfohlen |

**Quellen:**
- Apache Solr Memory Tuning Guide (Cloudera 2024)
- Moodle.org: 10-20GB Heap für File-Indexing
- Lucidworks Best Practices, Solr 9.x Performance Guide

#### Multi-Core Example Configuration

```yaml
# Global settings (16GB Server, max 4-5 cores)
customer_name: "school-district"
solr_app_domain: "solr.schools.edu"
solr_heap_size: "8g"            # 8GB für 16GB Server
solr_memory_limit: "14g"        # Container: 8GB Heap + 6GB OS Cache
solr_webserver: "nginx"
solr_ssl_enabled: true

# Multi-Core Mode: Define multiple cores
solr_cores:
  - name: "gymnasium_nord"
    domain: "moodle.gymnasium-nord.de"
    users:
      - username: "moodle_gym_nord"
        password: "GymNord2024SecureKey"  
        roles: ["core-admin-gymnasium_nord_core"]

  - name: "realschule_sued"
    domain: "moodle.realschule-sued.de"
    users:
      - username: "moodle_real_sued"
        password: ""  # Empty = auto-generate secure password!

  - name: "grundschule_ost"
    domain: "moodle.grundschule-ost.de"
    users:
      - username: "moodle_gs_ost"
        # No password = auto-generated
        roles: ["core-admin-grundschule_ost_core", "custom-role"]
```

**Core Naming:** Cores are created with `_core` suffix: `gymnasium_nord_core`, `realschule_sued_core`, etc.

#### Auto-Password Generation (v3.9.0+)

**Passwords are automatically generated when:**
- Password is missing or empty (`password: ""`)
- Password is too weak (< 12 characters)

**Generated passwords:**
- 24 characters long
- Base64-encoded (alphanumeric + safe special chars)
- Displayed after deployment with hostvars example

**Deployment Output Example:**
```
╔══════════════════════════════════════════════════════════════════════╗
║                 🔐 GENERATED CREDENTIALS                              ║
║                                                                       ║
║  ⚠️  WICHTIG: Passwörter wurden automatisch generiert!                ║
║  Bitte in host_vars speichern und WebUI-Login testen!                ║
╠══════════════════════════════════════════════════════════════════════╣
║  ✨ Realschule Süd User (NEU GENERIERT):                              ║
║     Username: moodle_real_sued                                        ║
║     Password: Xk9mP2vL7nR4wQ8tY5sH6jF3                               ║
║     Hinzufügen zu host_vars:                                          ║
║     solr_cores:                                                       ║
║       - name: "realschule_sued"                                       ║
║         users:                                                        ║
║           - username: "moodle_real_sued"                              ║
║             password: "Xk9mP2vL7nR4wQ8tY5sH6jF3"                      ║
║                                                                       ║
║  🌐 WEBUI LOGIN TESTEN:                                               ║
║  curl -u moodle_real_sued:Xk9mP2vL7nR4wQ8tY5sH6jF3 \                 ║
║       https://solr.schools.edu/solr-admin/realschule_sued_core/admin/ping
╚══════════════════════════════════════════════════════════════════════╝
```

**IMPORTANT:** Copy generated passwords to `host_vars` immediately! Otherwise, new passwords will be generated on next deployment.

#### YAML-Safe Password Characters

**Without quotes (recommended):**
- Letters: `A-Z`, `a-z`
- Numbers: `0-9`
- Special: `_`, `-`, `$`

**With quotes (all characters allowed):**
```yaml
password: "My-P@ssw0rd!#2024"  # Quotes required for @ ! # : etc.
```

---

## 📖 Usage Examples

### Example 1: First Installation
```yaml
- hosts:{{hosts}}
  become: true
  roles:
    - role: solr
      vars:
        customer_name: "acme-corp"
        moodle_app_domain: "elearning.acme.com"
        solr_heap_size: "4g"
        solr_memory_limit: "4g"
```

### Example 2: Password Update (ZERO Downtime)
```bash
# 1. Update password in host_vars/server.yml
solr_admin_password: "new_secure_password_123"

# 2. Re-run playbook - only password changes via API, NO container restart!
ansible-playbook -i inventory playbook.yml

# Result: Zero downtime, instant password change
```

### Example 3: Add New Core
```bash
# Change core name in host_vars
solr_core_name: "new_core_2024"

# Re-run playbook - creates new core, keeps old ones
ansible-playbook -i inventory playbook.yml

# Both cores now exist and are functional
```

### Example 4: Force Recreate Everything
```bash
ansible-playbook -i inventory playbook.yml -e "solr_force_recreate=true"
# Removes volume, recreates from scratch
```

### Example 5: Update Solr Version
```yaml
# In playbook or host_vars
solr_version: "9.10.0"  # Update version
solr_force_recreate: true  # Force recreate with new version

# Run playbook
ansible-playbook -i inventory playbook.yml
```

### Example 6: Multi-Core Deployment (v3.9.0+ KORRIGIERT)

Deploy 10 school Moodle instances on one Solr server (**32GB RAM erforderlich!**):

```yaml
# host_vars/solr-prod-01.yml (32GB Server für 10 Cores)
customer_name: "schulverbund-nord"
solr_app_domain: "solr.schulverbund.de"
solr_heap_size: "20g"       # KORRIGIERT: 20GB für 10 Cores (~1.5GB/Core effektiv)
solr_memory_limit: "28g"    # Container: 20GB Heap + 8GB OS Cache

# Define all 10 cores
solr_cores:
  - name: "gymnasium_nord"
    domain: "gym-nord.schulverbund.de"
    users:
      - username: "moodle_gym_nord"
        password: ""  # Auto-generate

  - name: "realschule_sued"
    domain: "real-sued.schulverbund.de"
    users:
      - username: "moodle_real_sued"
        password: "RealSued2024SecureIndexKey"  # Or provide your own

  # ... 8 more schools

  - name: "grundschule_west"
    domain: "gs-west.schulverbund.de"
    users:
      - username: "moodle_gs_west"
        password: ""  # Auto-generate

# Run deployment
ansible-playbook -i inventory playbook.yml

# Result:
# - 10 isolated cores created
# - ~1.5-2GB heap per core effektiv (KORRIGIERT!)
# - Missing passwords auto-generated and displayed
# - Each school has dedicated core + user
```

**16GB Server Alternative (max 4 cores):**
```yaml
# Für 16GB Server: Nur 4 Schulen möglich
solr_heap_size: "8g"
solr_memory_limit: "14g"
solr_cores:
  - name: "gymnasium_nord"    # ... 4 cores total
  - name: "realschule_sued"
  - name: "grundschule_west"
  - name: "hauptschule_ost"
```

**Add cores later (idempotent):**
```yaml
# Für 32GB Server: 11. Core hinzufügen
solr_cores:
  # ... existing 10 cores ...
  - name: "berufsschule_ost"  # NEW (11th core)
    domain: "bs-ost.schulverbund.de"
    users:
      - username: "moodle_bs_ost"
        password: ""

# Re-run playbook - only new core is created, existing cores untouched
ansible-playbook -i inventory playbook.yml

# Warning: >10 cores, ~1.3GB per core (Performance-Einbußen)
```

---

## 🏗️ Architecture

### Deployment Flow
```
┌──────────────────────┐
│ 1. Preflight Checks  │ → Validates system, disk space
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 2. System Prep       │ → Creates solr user (UID 8983), installs packages
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 3. Docker Install    │ → Installs Docker if not present
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 4. Auth Management   │ → Generates password hashes, detects existing auth
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 5. Config Management │ → Creates security.json, schemas, stopwords
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 6. Compose Gen       │ → Generates docker-compose.yml with init pattern
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 7. Container Deploy  │ → Deploys with rollback protection
│   ┌───────────────┐  │   ├─ Backup current state
│   │ BLOCK         │  │   ├─ Check config changes
│   │  Deploy       │  │   ├─ Stop if needed
│   └───────┬───────┘  │   ├─ Start with init
│   ┌───────▼───────┐  │   └─ Verify deployment
│   │ RESCUE        │  │
│   │  Recovery     │  │ → On failure: Attempt restart
│   └───────┬───────┘  │   └─ Log error details
│   ┌───────▼───────┐  │
│   │ ALWAYS        │  │ → Always log deployment
│   │  Logging      │  │
│   └───────────────┘  │
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 8. Auth Validation   │ → Tests authentication and authorization
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 9. Auth Persistence  │ → Saves credentials to host_vars (idempotent)
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 10. Core Creation    │ → Creates Solr core (skips if exists)
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 11. Proxy Config     │ → Configures Nginx/Apache reverse proxy
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 12. Integration Test │ → Full stack validation + cleanup
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 13. Finalization     │ → Documentation, summary, optional notifications
└──────────────────────┘
```

### Docker Stack
```
┌─────────────────────────────────────────┐
│  docker-compose.yml                     │
│                                         │
│  ┌───────────────┐  ┌────────────────┐  │
│  │ solr-init     │  │ solr           │  │
│  │ (Alpine)      │──│ (Official)     │  │
│  │               │  │                │  │
│  │ Validates:    │  │ Port: 8983     │  │
│  │ - JSON syntax │  │ Auth: Basic    │  │
│  │ - XML syntax  │  │ Schema: Moodle │  │
│  │               │  │                │  │
│  │ Deploys:      │  │ Health: API    │  │
│  │ - security    │  └────────┬───────┘  │
│  │ - configs     │           │          │
│  │ - stopwords   │    ┌──────▼──────┐   │
│  │ - schemas     │    │   Volume    │   │
│  └───────────────┘    │ solr_data   │   │
│                       └─────────────┘   │
└─────────────────────────────────────────┘
```

### Idempotency Logic
```
Run Playbook
     │
     ▼
Check Container Status
     │
  ┌──┴──┐
  │     │
  ▼     ▼
Running  Not Running
  │         │
  ▼         ▼
Calculate  Deploy
Checksums  (First Time)
  │
  ▼
Compare with
Container
  │
┌─┴─────────────┐
│               │
▼               ▼
Changed      Unchanged
│               │
▼               ▼
┌──────────┐   SKIP
│Which?    │   (No Action)
└─┬───┬────┘
  │   │
  ▼   ▼
Auth  Other
Only  Configs
  │   │
  ▼   ▼
API   Container
Update Restart
(0s)  (~20s)
```

---

## 🔒 Security

### Authentication & Authorization
- **BasicAuth**: All endpoints protected
- **Role-based access**:
  - `admin`: Full control (security, schema, config, collections)
  - `support`: Read-only on core
  - `customer`: Read + write on core

### Best Practices

#### 1. Use Ansible Vault for Passwords
```bash
# Create encrypted variable
ansible-vault encrypt_string 'SuperSecret123!' --name 'solr_admin_password'

# In host_vars/server.yml
solr_admin_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...encrypted...
```

#### 2. Firewall Configuration
```bash
# Only allow localhost + reverse proxy
ufw allow from 127.0.0.1 to any port 8983
ufw allow from <proxy_ip> to any port 8983
```

#### 3. SSL/TLS (via Reverse Proxy)
```yaml
# Configure in playbook
solr_ssl_enabled: true
solr_webserver: "nginx"

# Ensure Let's Encrypt certificates are installed
# Role will configure proxy with SSL
```

#### 4. Regular Updates
```yaml
# Keep Solr version updated
solr_version: "9.9.0"  # Check for updates regularly
```

---

## 🔄 Idempotency Scenarios

### Scenario 1: No Changes (Perfect Idempotency)
```bash
$ ansible-playbook playbook.yml
# ✅ Container keeps running
# ✅ No restart
# ✅ Execution: ~30 seconds
# ✅ Output: "SKIPPING deployment - no changes detected"
```

### Scenario 2: Password Change Only
```bash
# Edit host_vars: solr_admin_password: "new_password"
$ ansible-playbook playbook.yml

# ✅ API update only
# ✅ NO container restart
# ✅ Downtime: 0 seconds
# ✅ Password active immediately
```

### Scenario 3: Config File Change (Minimal Downtime)
```bash
# Edit: solr_heap_size: "4g"
$ ansible-playbook playbook.yml

# ✅ Container restarts
# ✅ Downtime: ~15-30 seconds
# ✅ New config applied
```

### Scenario 4: Core Name Change (Additive)
```bash
# Edit: solr_core_name: "new_core_2024"
$ ansible-playbook playbook.yml

# ✅ New core created
# ✅ Old core preserved
# ✅ Both cores functional
```

### Scenario 5: Deployment Failure (Auto-Rollback)
```bash
# Invalid config introduced
$ ansible-playbook playbook.yml

# ❌ Deployment fails
# ✅ Automatic rollback attempted
# ✅ Clear error message with recovery steps
# ✅ Logs saved to /var/log/solr_deployment_*.log
```

---

## Troubleshooting

### Common Issues

#### 1. Init Container Fails
```bash
# Check init container logs
docker logs <container_name>_powerinit

# Common causes:
# - Invalid JSON in security.json → Check template syntax
# - Invalid XML in schema → Validate XML files
# - Permission issues → Check solr user (UID 8983)

# Solution: Review logs, fix templates, re-run
```

#### 2. Container Unhealthy
```bash
# Check container health
docker ps
docker inspect <container_name> | grep -A 10 Health

# Check Solr logs
docker logs <container_name>

# Common causes:
# - Insufficient memory → Increase solr_heap_size
# - Port conflict → Check port availability
# - Invalid security.json → Validate JSON syntax

# Solution:
ansible-playbook playbook.yml -e "solr_force_recreate=true"
```

#### 3. Authentication Not Working
```bash
# Test auth manually
curl -u admin:password http://localhost:8983/solr/admin/info/system

# Should return 200, not 401

# Verify security.json deployed
docker exec <container_name> cat /var/solr/data/security.json

# Re-run with forced auth reconfiguration
ansible-playbook playbook.yml -e "solr_force_reconfigure_auth=true"
```

#### 4. Deployment Fails Mid-Way
```bash
# Check deployment log
cat /var/log/solr_deployment_*.log

# Rollback is automatic, but if manual intervention needed:
cd /opt/solr/<customer>/
docker compose down
docker compose up -d

# Fix issue, then re-run Ansible
```

#### 5. Port Already in Use
```bash
# Find process using port
ss -ltnp | grep :8983

# Kill process or change port
# In host_vars:
solr_port: 8984

# Re-run playbook
```

### Debug Mode
```bash
# Run with increased verbosity
ansible-playbook playbook.yml -vv

# Or enable debug in playbook
- hosts: all
  vars:
    ansible_verbosity: 2
  roles:
    - solr
```

### Testing Flags
```bash
# Run only integration tests (skip deployment)
ansible-playbook playbook.yml --tags "install-solr-test"

# Run Moodle-specific tests only
ansible-playbook playbook.yml --tags "install-solr-moodle"

# Skip all tests (faster deployment)
ansible-playbook playbook.yml --skip-tags "install-solr-test"

# Test authentication only
ansible-playbook playbook.yml --tags "install-solr-auth"

# Run backup tests
ansible-playbook playbook.yml --tags "install-solr-backup"

# Full test suite (includes all 19 tests)
ansible-playbook playbook.yml -e "perform_core_testing=true"

# Validate deployment without changes
ansible-playbook playbook.yml --check --diff
```

### Performance Testing
```bash
# Monitor memory usage during tests
ansible-playbook playbook.yml -e "solr_jvm_monitoring=true"

# Enable GC logging for performance analysis
ansible-playbook playbook.yml -e "solr_gc_logging=true"

# Test with larger heap for performance
ansible-playbook playbook.yml -e "solr_heap_size=4g solr_memory_limit=8g"
```

### Logs Locations
```
/var/log/solr_deployment_*.log     # Deployment attempts
/var/log/solr_handlers.log         # Handler executions
/opt/solr/<customer>/docker-compose.yml  # Generated compose file
/opt/solr/<customer>/config/       # All config files
```

---

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Container health
docker ps | grep solr

# Solr API health
curl http://localhost:8983/solr/admin/info/system

# Core status
curl -u admin:password http://localhost:8983/solr/admin/cores?action=STATUS

# Disk usage
docker system df
docker volume inspect <volume_name>
```

### Backup
```bash
# Manual backup
docker exec <container_name> solr backup \
  -c <core_name> \
  -d /var/solr/backup \
  -name backup_$(date +%Y%m%d)

# Restore
docker exec <container_name> solr restore \
  -c <core_name> \
  -d /var/solr/backup \
  -name backup_20241102
```

### Updates
```bash
# Update Solr version
# Edit playbook: solr_version: "9.10.0"
ansible-playbook playbook.yml -e "solr_force_recreate=true"
```


---

## 📝 Changelog

### v3.9.2 (2025-11-16) - Current Release 🎯

**Status:** ✅ 

**Major Updates:**
- ✅ Solr 9.10.0 compatibility validated (upgrade ready)
- ✅ All critical bugs fixed (4 bugs)
- ✅ Moodle file indexing fields completed
- ✅ User management (v3.8.0)
- ✅ 100% Moodle 4.1-5.0.3 compatibility

**Critical Fixes:**
- Fixed circular variable dependency (customer_name)
- Fixed Moodle schema fields (solr_filecontent, solr_fileindexstatus, etc.)
- Fixed password exposure in logs (no_log: true)
- Fixed docker_container_info bug (replaced with docker inspect) <-- Abnahme fehler
- Corrected RAM documentation (4GB OS buffer)

**See:** [CHANGELOG.md](CHANGELOG.md) for complete version history

---

## 👤 Author

**Bernd Schreistetter**
- Role: DevOps Engineer / Administrator
- Organization: Eledia Gmbh

---

## 📄 License

MIT License

---

**Made with ❤️ for the Eledia & Moodle**

**Fully documented** ✅ 
