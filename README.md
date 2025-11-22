# Ansible Role: Solr

![Version](https://img.shields.io/badge/version-4.0.0-blue)
![Ansible](https://img.shields.io/badge/ansible-2.10.12+-green)
![Solr](https://img.shields.io/badge/solr-9.9.0)
![Moodle](https://img.shields.io/badge/moodle-4.1--5.0.3-purple)
![Tests](https://img.shields.io/badge/tests-dev%20ready-brightgreen)
![Status](https://img.shields.io/badge/status-Dev%20deployed-success)

Ansible role for deploying Apache Solr 9.9.0+ (9.10 validated) with BasicAuth, Moodle schema support (file indexing + Schema API), full idempotency, multi-core support and user management

**Author**: Bernd Schreistetter
**Organization**: Eledia GmbH
**Project Timeline**: 24.09.2025 - 18.11.2025 (56 days)
**Production Status**: ✅ Deployed and tested on Hetzcloud server (4 cores, 8GB RAM should be 16 for 4 Cores)

---

## What's New in v4.0.0 (Major Simplification)

### Breaking Changes
- **REMOVED**: Apache/Nginx proxy configuration (use Caddy externally)
- **REMOVED**: SSL/TLS configuration (handled by Caddy)
- **CHANGED**: Schema factory to ManagedIndexSchemaFactory

### New Features
- **Moodle Schema API Support**: Moodle can now add fields via POST `/schema` (add-field)
- **Empty Core Option**: `solr_empty_core: true` creates minimal schema for Moodle API registration
- **Simplified Configuration**: No more proxy/SSL variables needed
- **Multi-Core empty_core**: Per-core `empty_core: true/false` option

### Why v4.0.0?
- Caddy handles reverse proxy and SSL better than Apache/Nginx configuration
- ManagedIndexSchemaFactory required for Moodle's Schema API
- Simpler deployment: Focus on Solr, not proxy configuration

### Migration from v3.x
1. Remove `solr_proxy_enabled`, `solr_ssl_enabled`, `solr_webserver` from host_vars
2. Configure Caddy separately for reverse proxy and SSL
3. If using Moodle Schema API: Set `solr_empty_core: true`

### Previous Release (v3.9.18)
- Multi-Core Validated: 4 cores running on 16GB server
- Username Conventions: Auto-role assignment
- Full idempotency support

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Single-Core Mode](#single-core-mode)
  - [Multi-Core Mode](#multi-core-mode)
  - [Empty Core Mode](#empty-core-mode)
  - [Username Conventions](#username-conventions)
- [Architecture](#architecture)
- [Security](#security)
- [Monitoring](#monitoring)
- [Backup & Recovery](#backup--recovery)
- [Troubleshooting](#troubleshooting)
- [Known Limitations](#known-limitations)
- [Production Deployment](#production-deployment)
- [Development](#development)
- [License](#license)

---

## ✨ Features

### Core Features
- ✅ **Apache Solr 9.9.0+** - Latest stable version
- ✅ **Docker-based Deployment** - Isolated, reproducible environments
- ✅ **Multi-Core Support** - Run multiple Solr cores per server
- ✅ **Moodle Schema** - Complete schema for Moodle 4.1-5.0.3 (file indexing support)
- ✅ **Full Idempotency** - Unlimited re-runs on same server, no side effects
- ✅ **Username Conventions** - Automatic role assignment based on username patterns
- ✅ **Task File Optimization** - 25 organized task files reduced from 28

### Security Features
- **BasicAuth Plugin** - Username/password authentication
- **RuleBasedAuthorizationPlugin** - Role-based access control
- **SHA256 Double-Hashing** - Secure password storage
- **Auto-Password Generation** - Secure 24-character passwords if not set

### Schema Features (NEW in v4.0.0)
- **ManagedIndexSchemaFactory** - Allows dynamic schema modifications via API
- **Moodle Schema API** - Moodle can add fields via POST `/schema` (add-field)
- **Empty Core Mode** - Minimal schema for Moodle API registration

### Operational Features
- **PowerInit v1.7.0** - Init-container pattern with checksum verification
- **Integration Tests** - Automated smoke tests after deployment
- **External Proxy** - Use Caddy for reverse proxy and SSL (not managed by this role)

### Developer Features
- 🛠️ **Host_vars Persistence** - Credentials auto-saved to inventory
- 🛠️ **Credential Display** - Shows all generated passwords after deployment
- 🛠️ **Rundeck Integration** - JSON output for automation
- 🛠️ **Deployment Documentation** - Auto-generated docs in `/opt/solr/`
- 🛠️ **Quick Reference Cards** - Management commands and URLs

---

## 📦 Requirements

### System Requirements
- **OS**: Debian 11/12
- **RAM**:
  - Single-Core: 2.5GB minimum
  - Multi-Core (4 cores): 16GB recommended
  - Multi-Core (8 cores): 32GB recommended
- **Disk**: 20GB minimum (50GB+ for production)
- **CPU**: 2+ cores recommended

### Software Requirements
- **Ansible**: 2.10.12 or higher
- **Docker**: 20.10 or higher (installed automatically if missing)
- **Caddy** (optional): For reverse proxy and SSL termination (external to this role)

### Network Requirements
- Port 8983 (Solr, localhost only - not exposed publicly)
- Port 80/443 (via Caddy or other reverse proxy)
- Outbound HTTPS for Docker image pulls

---

## 🚀 Installation

### 1. Install the Role

```bash
# Or clone from Git
### 2. Create Inventory

```bash
mkdir -p ansible-inventory/my-moodle/host_vars
```
### 3. Create host_vars File

See [Configuration](#configuration) section for examples.

---

## ⚡ Quick Start

### Single-Core Deployment

**Minimal host_vars configuration:**

```yaml
---
customer_name: mycompany
solr_app_domain: solr.example.com

# Authentication (required)
solr_admin_password: "ChangeMeSecure123!"
solr_support_password: "AlsoSecure456!"
solr_moodle_password: "MoodlePassword789!"

# Empty Core Mode (optional - for Moodle Schema API)
# Set to true if Moodle should create schema via API
solr_empty_core: false
```

> **Note**: SSL/TLS and reverse proxy are handled externally by Caddy.
> Configure Caddy to proxy requests to `localhost:8983`.

**Run playbook:**

```bash
ansible-playbook -i inventory install-solr.yml
```

### Multi-Core Deployment

See [Multi-Core Mode](#multi-core-mode) section for detailed configuration.

---

## ⚙️ Configuration

### Single-Core Mode

Single-Core mode is the default and simplest configuration. One Solr instance serves one Moodle installation.

**Example host_vars:**

```yaml
---
customer_name: school1
solr_app_domain: school1-solr.example.com

# Basic Configuration
solr_version: "9.9.0"
solr_core_name_override: "school1_core"
solr_port: 8983

# Authentication
solr_admin_user: school1_admin
solr_admin_password: "SecurePassword123"
solr_support_user: school1_support
solr_support_password: "SupportPassword456"
solr_moodle_user: school1_moodle
solr_moodle_password: "MoodlePassword789"

# Resource Limits (16GB Server)
solr_heap_size: "8g"
solr_memory_limit: "14g"

# Backup (optional)
solr_backup_enabled: true
solr_backup_schedule: "0 3 * * *"  # 3 AM daily
solr_backup_retention: 14  # days
```

### Multi-Core Mode

Multi-Core mode allows multiple isolated Solr cores on one server, ideal for multi-tenant Moodle hosting.

**Important:**
- Each core requires ~1.5-2GB RAM
- 16GB server: Max 4 cores
- 32GB server: Max 10 cores

**Example host_vars (4-core setup):**

```yaml
---
customer_name: school_district
solr_app_domain: district-solr.example.com

# Global Admin Users (access ALL cores)
solr_admin_user: district_admin
solr_admin_password: "GlobalAdminPass123"
solr_support_user: district_support
solr_support_password: "GlobalSupportPass456"
solr_moodle_user: district_global
solr_moodle_password: "GlobalMoodlePass789"

# Multi-Core Configuration
solr_cores:
  # Elementary School
  - name: elementary
    domain: elementary.district.edu
    users:
      - username: elementary_admin
        password: "ElemAdminPass123"
        # No roles: line needed - auto-assigned based on username!
      - username: elementary_moodle
        password: "ElemMoodlePass456"
      - username: elementary_readonly
        password: "ElemReadonlyPass789"

  # Middle School
  - name: middle
    domain: middle.district.edu
    users:
      - username: middle_admin
        password: "MiddleAdminPass123"
      - username: middle_moodle
        password: "MiddleMoodlePass456"
      - username: middle_readonly
        password: "MiddleReadonlyPass789"

  # High School
  - name: high
    domain: high.district.edu
    users:
      - username: high_admin
        password: "HighAdminPass123"
      - username: high_moodle
        password: "HighMoodlePass456"
      - username: high_readonly
        password: "HighReadonlyPass789"

  # Adult Education
  - name: adult_ed
    domain: adulted.district.edu
    users:
      - username: adult_ed_admin
        password: "AdultEdAdminPass123"
      - username: adult_ed_moodle
        password: "AdultEdMoodlePass456"
      - username: adult_ed_readonly
        password: "AdultEdReadonlyPass789"

# Resource Limits (16GB Server, 4 Cores)
solr_heap_size: "2g"        # 2GB per core
solr_memory_limit: "4g"     # Total limit
```

### Username Conventions

**Auto-Role Assignment (v3.9.12+):**

The role automatically assigns roles based on username patterns:

| Username Pattern | Auto-Assigned Role | Permissions |
|------------------|-------------------|-------------|
| `*_admin` | `["admin"]` | Full access to everything |
| `*_moodle` | `["moodle"]` | Read/write access to cores |
| `*_readonly` | `["support"]` | Read-only access |

**Examples:**
- `school1_admin` → Gets `admin` role automatically
- `school1_moodle` → Gets `moodle` role automatically
- `school1_readonly` → Gets `support` role automatically

**Benefits:**
- ✅ No need to define `roles:` in host_vars
- ✅ Convention over configuration
- ✅ Consistent across all deployments
- ✅ Less config = fewer errors

**Override Behavior:**
If you explicitly define `roles:` in host_vars, that takes precedence over the username convention.

---

## 🏗️ Architecture

### Deployment Flow

```
Ansible Control Node
    ↓
1. Generate configs (security.json, solrconfig.xml, docker-compose.yml)
    ↓
2. Upload to /opt/solr/config/ on target server
    ↓
3. Docker Compose starts:
   ├── Init-Container (PowerInit v1.7.0)
   │   ├── Verify checksums
   │   ├── Deploy configs if changed
   │   └── Exit
   └── Solr Container
       ├── Load configs from /var/solr/data/
       ├── Create/reload cores
       └── Start Solr on port 8983
    ↓
4. External Reverse Proxy (Caddy recommended)
   ├── SSL Termination (handled externally)
   ├── Reverse Proxy to localhost:8983
   └── NOT managed by this role
```

### Directory Structure

```
/opt/solr/
├── docker-compose.yml          # Container orchestration
├── .env                        # Environment variables
├── config/                     # Solr configuration
│   ├── security.json          # Authentication & authorization
│   ├── solrconfig.xml         # Solr core config
│   ├── managed-schema.xml     # Moodle schema definition
│   └── credentials.yml        # Password storage (dev only!)
├── data/                       # Solr data (Docker volume)
│   ├── security.json          # Deployed security config
│   ├── configsets/            # ConfigSets
│   └── <core_name>/           # Core data directories
├── logs/                       # Solr logs
├── backups/                    # Backup directory
├── DEPLOYMENT_INFO.md          # Auto-generated deployment docs
└── QUICK_REFERENCE.txt         # Quick reference card
```

### Task File Structure (v3.9.15)

**25 Organized Task Files:**

```
tasks/
├── main.yml                              # Main orchestrator
├── preflight_checks.yml                  # Pre-deployment validation
├── system_preparation.yml                # OS & packages
├── docker_installation.yml               # Docker setup
├── auth_management.yml                   # Password hashing
├── auth_detection.yml                    # Detect existing auth
├── auth_password_generator.yml           # Generate passwords
├── auth_api_update.yml                   # Hot-reload via API
├── auth_validation.yml                   # Test authentication
├── auth_persistence.yml                  # Save to host_vars
├── user_management.yml                   # User orchestration
├── user_management_hash.yml              # Hash single-core users
├── user_management_hash_multicore.yml    # Hash multi-core users
├── user_update_live.yml                  # Zero-downtime updates
├── config_management.yml                 # Generate configs
├── compose_generation.yml                # Docker Compose file
├── container_deployment.yml              # Deploy containers
├── core_management.yml                   # Create & reload cores ⭐ NEW
├── core_creation_single.yml              # Single-core creation
├── core_creation_worker.yml              # Multi-core worker
├── rundeck_integration.yml               # Rundeck job templates (optional)
├── integration_tests.yml                 # Smoke tests
├── moodle_test_documents.yml             # Moodle doc tests
├── finalization.yml                      # Final summary
└── rundeck_integration.yml               # Rundeck output
```

**Changes in v3.9.15:**
- **Removed:** `core_creation.yml`, `core_reload.yml`, `credentials_display.yml`, `rundeck_output.yml`
- **Added:** `core_management.yml` (consolidates core creation + reload)
- **Result:** 28 → 25 files (-11%), better organization

---

## 🔒 Security

### Authentication

**BasicAuthPlugin** with SHA256 double-hashing:

```json
{
  "authentication": {
    "class": "solr.BasicAuthPlugin",
    "blockUnknown": true,
    "credentials": {
      "admin": "hash1 salt1",
      "support": "hash2 salt2",
      "moodle": "hash3 salt3"
    }
  }
}
```

### Authorization

**RuleBasedAuthorizationPlugin** with global permissions:

```json
{
  "authorization": {
    "class": "solr.RuleBasedAuthorizationPlugin",
    "permissions": [
      { "name": "all", "role": "admin" },
      { "name": "read", "role": ["admin", "support", "moodle"] },
      { "name": "update", "role": ["admin", "moodle"] }
    ],
    "user-role": {
      "admin": ["admin"],
      "support": ["support"],
      "moodle": ["moodle"]
    }
  }
}
```

**Important Limitation:**
- Per-core permissions do **NOT** work in Solr Standalone mode
- All authenticated users can access all cores
- For per-core isolation, use SolrCloud with ZooKeeper

### Password Storage

**Production:**
- Stored in host_vars 
- Encrypted with Ansible Vault (recommended)
- Hashed in Solr (SHA256 double-hash)

**Development:**
- Also saved to `/opt/solr/config/credentials.yml` (plaintext)
- **⚠️ Delete this file in production!**

### External Reverse Proxy (Caddy Recommended)

**Note:** SSL/TLS and Apache/Nginx proxy configuration was removed in v4.0.0.
Use an external reverse proxy like Caddy for:
- SSL/TLS termination
- Reverse proxy to localhost:8983
- Public HTTPS access

**Example Caddy configuration:**

```
solr.example.com {
    reverse_proxy localhost:8983
}
```

**Why Caddy?**
- Automatic HTTPS with Let's Encrypt
- Zero-config SSL certificate management
- Simple configuration syntax
- No Apache/Nginx module configuration needed

---

## 📊 Monitoring

### Health Checks

**Automated health checks:**
- `/admin/ping` - Core ping (no auth required)
- `/admin/cores?action=STATUS` - Core status
- `/admin/system` - System info

**Example:**

```bash
curl http://localhost:8983/solr/admin/ping
# Returns: {"status":"OK"}

curl -u admin:password http://localhost:8983/solr/admin/cores?action=STATUS
# Returns: Core status JSON
```

### Logs

**Log locations:**
- Solr logs: `/opt/solr/logs/` (Docker volume)
- Docker logs: `docker logs solr_<customer>`

**View logs:**

```bash
# Solr container logs
docker logs -f solr_customer

# Follow Solr logs in real-time
docker exec solr_customer tail -f /var/solr/logs/solr.log
```

### Metrics

**Resource monitoring:**

```bash
# Container stats
docker stats solr_customer

# Volume size
docker volume inspect solr_data_customer -f "{{.Mountpoint}}" | xargs du -sh

# Memory usage
free -h

# Disk usage
df -h /opt/solr
```

---

### Manual Backup

```bash
# Backup via Solr API
curl -u admin:password \
  "http://localhost:8983/solr/core_name/replication?command=backup&location=/opt/solr/backups&name=manual_backup"

# Or use Docker volume backup
docker run --rm \
  -v solr_data_customer:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/solr-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore

```bash
# Restore via Solr API
curl -u admin:password \
  "http://localhost:8983/solr/core_name/replication?command=restore&location=/opt/solr/backups&name=manual_backup"

# Or restore Docker volume
docker run --rm \
  -v solr_data_customer:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/solr-backup-20251118.tar.gz -C /
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "Permission Denied" in Admin UI

**Symptom:** After login, Admin UI shows permission errors

**Cause:** Browser caching old security config

**Solution:**
```bash
# Clear browser cache (Ctrl+Shift+Delete)
# Or use Incognito mode

# Test API directly
curl -u admin:password http://localhost:8983/solr/admin/authorization
# Should return security.json
```

#### 2. Container Won't Start

**Check logs:**
```bash
docker logs solr_customer

# Common issues:
# - Port 8983 already in use
# - Insufficient memory
# - Invalid security.json syntax
```

**Solution:**
```bash
# Check port usage
netstat -tulpn | grep 8983

# Check memory
free -h

# Validate security.json
docker exec solr_customer cat /var/solr/data/security.json | python3 -m json.tool
```

#### 3. Core Not Found

**Symptom:** 404 when accessing core

**Check core status:**
```bash
curl -u admin:password http://localhost:8983/solr/admin/cores?action=STATUS
```

**Reload core:**
```bash
curl -u admin:password \
  "http://localhost:8983/solr/admin/cores?action=RELOAD&core=core_name"
```

#### 4. Out of Memory

**Symptom:** Java heap space errors, slow performance

**Check heap usage:**
```bash
docker stats solr_customer

# Adjust heap in host_vars
solr_heap_size: "8g"        # Increase this
solr_memory_limit: "16g"    # And this
```

**Re-deploy:**
```bash
ansible-playbook -i inventory install-solr.yml
```

### Debug Mode

**Enable verbose logging:**

```yaml
solr_log_level: DEBUG  # In host_vars
```

**View detailed logs:**
```bash
docker logs -f solr_customer 2>&1 | grep -i error
```

---

## ⚠️ Known Limitations & Hurdles

### 📊 Quick Summary: What Works vs What Doesn't

**✅ What Works (Validated):**
- ✅ Solr server deployment and operation
- ✅ Multi-core support (4 cores tested on 16GB RAM)
- ✅ User authentication (BasicAuth with SHA256 hashing)
- ✅ Role-based permissions (admin, moodle, support)
- ✅ Core access (all cores accessible to admin)
- ✅ Moodle search integration
- ✅ Smoke tests (10/10 passed)
- ✅ Idempotent re-runs (unlimited re-deployments)
- ✅ Automated backups
- ✅ SSL/TLS proxy
- ✅ Dev deployment

**⚠️ Known Limitations:**
- ⚠️ Per-core access control requires SolrCloud (Solr Standalone limitation)
- ⚠️ Resource planning critical (2GB RAM per core minimum)

**Bottom Line:**
> 🎉 **The server is ready to deploy!** All core functionality works. The only limitation is a Solr architectural constraint (per-core permissions require SolrCloud).

---

### 1. Solr Standalone Mode - Per-Core Permissions

**Official Limitation:**

According to [official Apache Solr documentation](https://solr.apache.org/guide/solr/latest/deployment-guide/rule-based-authorization-plugin.html):

> "You can't limit access to a specific core through security.json - if you need to limit which users can access which sets of data, you'll have to use SolrCloud and the collections parameter."

**What This Means:**
- ✅ User authentication (API) works 
- ✅ Role-based permissions works
- ✅ Multi-core isolation works (separate indexes)
- ✅ Admin can access all cores
- ✅ All smoke tests pass (10/10)
- ❌ Cannot restrict specific user to only one core
- ❌ All authenticated users can access all cores on the same server

**Production Impact:**
- **LOW for most use cases** - Each Moodle instance uses separate core
- **MEDIUM if you need strict access control** - Use separate Solr servers per tenant

**Workaround Options:**
1. **Separate Solr Servers** (recommended for strict isolation)
   ```yaml
   # Deploy one Solr server per high-security tenant
   # Each gets own VM/container with own credentials
   ```

2. **SolrCloud with ZooKeeper** (future enhancement)
   ```yaml
   # NOT SUPPORTED IN THIS ROLE YET
   # Requires separate ZooKeeper cluster
   solr_cloud_enabled: true
   solr_zookeeper_hosts:
     - zk1.example.com:2181
     - zk2.example.com:2181
   ```

3. **Accept Global Access** (current production setup)
   - Each Moodle has separate core (data isolated)
   - All authenticated users can technically access any core
   - Use strong passwords and audit logging

---

### 2. Resource Requirements - Careful Planning Needed

**This Was a Major Hurdle:**

I originally calculated **600MB per core** (leading to 10 cores on 16GB server)

**Reality Check (v3.9.2 Fix):**
- Solr caches are **PER-CORE**, not shared
- Each core needs **1.5-2GB RAM minimum**
- 16GB server → **Max 4 cores**

**Correct Server Sizing:**

| Server RAM | Max Cores | Heap per Core | Notes |
|-----------|-----------|---------------|-------|
| 8GB | 1-2 | 2-3GB | Small deployments |
| 16GB | 4 | 2GB | SRH Campus (production validated ✅) |
| 32GB | 8-10 | 2-3GB | Large multi-tenant |
| 64GB | 15-20 | 3GB | Enterprise scale |

**Production Validation:**
- ✅ SRH Campus: 4 cores on 16GB RAM
- ✅ Memory usage: 2.27GiB / 4GiB (56% - healthy)
- ✅ All smoke tests passed
- ✅ No OOM errors

**Lesson Learned:**
> Don't over-provision cores! Always test with realistic workloads. Monitor `docker stats` in production.

---

## 🚀 Deployment

### Pre-Deployment Checklist

- [ ] Server meets minimum requirements (RAM, disk, CPU)
- [ ] DNS records point to server
- [ ] SSL certificates obtained (Let's Encrypt)
- [ ] host_vars configured and tested
- [ ] Ansible Vault configured for passwords
- [ ] Backup schedule planned
- [ ] Monitoring/alerting configured
- [ ] Firewall rules configured

### SSL Certificate Setup

```bash
# 1. Install certbot
apt-get install -y certbot python3-certbot-apache

# 2. Stop Apache temporarily
systemctl stop apache2

# 3. Obtain certificate
certbot certonly --standalone -d solr.example.com

# 4. Configure auto-renewal
systemctl enable certbot.timer
systemctl start certbot.timer

# 5. Verify renewal works
certbot renew --dry-run
```

### Deploy

```bash
# 1. Encrypt passwords with Ansible Vault
ansible-vault encrypt host_vars/hostname

# 2. Run deployment
ansible-playbook -i inventory install-solr.yml --ask-vault-pass

# 3. Verify deployment
curl -u admin:password https://solr.example.com/solr-admin/admin/ping

# 4. Run smoke tests
# (automatically run during deployment)
```

### Post-Deployment

```bash
# 1. Delete plaintext credentials file
rm /opt/solr/config/credentials.yml

# 2. Verify backups
ls -lh /opt/solr/backups/

# 3. Test Moodle connectivity
# Configure Moodle search plugin with:
# - Host: solr.example.com
# - Port: 8983
# - Path: /solr-admin/<core_name>
# - Username: moodle
# - Password: (from credentials)

# 4. Monitor logs
docker logs -f solr_customer
```

### Best Practices

1. **Use Ansible Vault** for all passwords
2. **Delete credentials.yml** from /opt/solr/config/
3. **Enable automated backups** with 14+ day retention
4. **Monitor disk usage** (Solr index grows over time)
5. **Set up log rotation** (Docker logs can grow large)
6. **Test restore procedure** before you need it
7. **Document your setup** (use auto-generated docs)
8. **Plan for scaling** (monitor RAM usage per core)

---

## 💻 Development

### Running Tests

**Smoke tests run automatically during deployment:**

```yaml
# In playbook:
- name: Integration tests
  include_tasks: integration_tests.yml

- name: Moodle document tests
  include_tasks: moodle_test_documents.yml
```

**Test results:**
- 10 tests total (indexing + search)
- 100% pass required for production
- Results displayed at end of deployment

**Manual test:**

```bash
# Test authentication
curl -u admin:password http://localhost:8983/solr/admin/authorization

# Test indexing
curl -u admin:password \
  -H "Content-Type: application/json" \
  -d '[{"id":"test1","title":"Test"}]' \
  http://localhost:8983/solr/core_name/update/json/docs

# Test search
curl -u admin:password \
  "http://localhost:8983/solr/core_name/select?q=title:Test"
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (especially re-runs!)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

**Code Standards:**
- All tasks must be idempotent
- Use descriptive task names with prefixes (`install-solr - `)
- Document complex logic with comments
- Test on clean server AND re-runs
- Update README with new features

---

## 📄 License

MIT License

Copyright (c) 2025 Eledia GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## 📞 Support

**Email:** support@eledia.de
**Documentation:** https://docs.eledia.de/solr
---

**Version:** 4.0.0
**Last Updated:** 2025-11-22
**Status:** Rollout Ready
**Tested On:** Hetzner Cloud Server (4 cores, 8GB RAM)
