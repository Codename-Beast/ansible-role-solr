# Ansible Role: Solr

![Version](https://img.shields.io/badge/version-1.3.2-blue)
![Ansible](https://img.shields.io/badge/ansible-2.10.12+-green)
![Solr](https://img.shields.io/badge/solr-9.9.0-orange)
![Moodle](https://img.shields.io/badge/moodle-4.1--5.0.x-purple)

Production-ready Ansible role for deploying Apache Solr 9.9.0 with BasicAuth, Moodle schema support, full idempotency, and automatic rollback.

**Author**: Bernd Schreistetter
**Organization**: Eledia
**License**: MIT

---

## 🎯 Features

### Production-Grade Capabilities
- ✅ **Full Idempotency** - Run unlimited times without side effects
- ✅ **Automatic Rollback** - Deployment failure recovery with block/rescue/always
- ✅ **Selective Password Updates** - Change passwords without container restart (ZERO downtime)
- ✅ **Smart Core Management** - Core name changes create new cores, old ones preserved
- ✅ **Docker Compose v2** - Modern init-container pattern for config deployment
- ✅ **BasicAuth Security** - Role-based access control (admin/support/customer)
- ✅ **Moodle Schema** - Pre-configured for Moodle 4.1-5.0.x compatibility

### Reliability Features
- ✅ **Rollback Mechanism** - Automatic recovery on deployment failure
- ✅ **Error Handling** - Comprehensive logging and clear error messages
- ✅ **Health Checks** - Docker healthcheck + Ansible validation
- ✅ **Config Validation** - JSON/XML syntax checks before deployment
- ✅ **Deployment Logging** - All attempts logged to /var/log/solr_deployment_*.log

### Bug Fixes in v1.3.2
- ✅ **11 Critical Bugs Fixed** - All runtime errors resolved
- ✅ **Port Check Fix** - Uses `ss` instead of netstat
- ✅ **User Management** - Solr user (UID 8983) properly created
- ✅ **Validation Tools** - jq and libxml2-utils installed
- ✅ **Password Generation** - Persistent path instead of /dev/null
- ✅ **Template Fixes** - Correct references, shell escaping fixed
- ✅ **Test Cleanup** - Integration and Moodle tests clean up after themselves
- ✅ **Core Name Sanitization** - Proper length handling (max 50 chars)
- ✅ **Version Mapping** - Consistent Moodle version support
- ✅ **Stopwords** - Complete stopwords.txt (EN + DE)

---

## 📋 Requirements

### System Requirements
- **OS**: Ubuntu 20.04/22.04, Debian 10/11
- **Ansible**: 2.10.12 or higher
- **Python**: 3.8+
- **Docker**: 20.10+ with Compose v2
- **Memory**: Minimum 2GB RAM (4GB recommended)
- **Disk**: Minimum 10GB free space

### Ansible Collections
```bash
ansible-galaxy collection install community.docker
```

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
# From Ansible Galaxy (when published)
ansible-galaxy install bernd.solr

# Or from Git
git clone https://github.com/yourorg/ansible-role-solr.git roles/solr
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
        solr_admin_password: "{{ vault_solr_admin_password }}"
        solr_support_password: "{{ vault_solr_support_password }}"
        solr_customer_password: "{{ vault_solr_customer_password }}"
```

### 4. Run
```bash
ansible-playbook -i inventory/hosts playbook.yml
```

---

## ⚙️ Configuration

### Required Variables
```yaml
customer_name: "your-company"           # Customer identifier
moodle_app_domain: "moodle.example.com" # Your Moodle domain
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
solr_version: "9.9.0"                    # Solr version
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
```

---

## 📖 Usage Examples

### Example 1: First Installation
```yaml
- hosts: production
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

---

## 🏗️ Architecture

### Deployment Flow
```
┌──────────────────────┐
│ 1. Preflight Checks  │ → Validates system, Ansible version, disk space
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
│  ┌───────────────┐  ┌────────────────┐ │
│  │ solr-init     │  │ solr           │ │
│  │ (Alpine)      │──│ (Official)     │ │
│  │               │  │                │ │
│  │ Validates:    │  │ Port: 8983    │ │
│  │ - JSON syntax │  │ Auth: Basic   │ │
│  │ - XML syntax  │  │ Schema: Moodle│ │
│  │               │  │                │ │
│  │ Deploys:      │  │ Health: API   │ │
│  │ - security    │  └────────┬───────┘ │
│  │ - configs     │           │         │
│  │ - stopwords   │    ┌──────▼──────┐  │
│  │ - schemas     │    │   Volume    │  │
│  └───────────────┘    │ solr_data   │  │
│                       └─────────────┘  │
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

### Scenario 2: Password Change Only (ZERO Downtime)
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

## 🐛 Troubleshooting

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

# Update role
ansible-galaxy install bernd.solr --force
```

---

## 📚 Documentation

- [BUG_SEARCH_ANALYSIS_v1.3.2.md](BUG_SEARCH_ANALYSIS_v1.3.2.md) - All 11 bugs documented and fixed
- [SENIOR_DEVELOPER_REVIEW_v1.3.1.md](SENIOR_DEVELOPER_REVIEW_v1.3.1.md) - Code review findings
- [TEAM_LEAD_REVIEW_v1.3.1.md](TEAM_LEAD_REVIEW_v1.3.1.md) - Architecture assessment
- [handlers/main.yml](handlers/main.yml) - Event handlers documentation

---

## 📝 Changelog

### v1.3.2 (2025-11-02) - Current
- ✅ **CRITICAL**: Fixed 11 production bugs
- ✅ **CRITICAL**: Added rollback mechanism (block/rescue/always)
- ✅ **CRITICAL**: Fixed shell escaping in docker-compose template
- ✅ Improved error handling with detailed logging
- ✅ Expanded handlers (6 new handlers)
- ✅ Fixed port check (ss instead of netstat)
- ✅ Created solr system user (UID 8983)
- ✅ Added jq and libxml2-utils packages
- ✅ Fixed password generator (/dev/null → persistent path)
- ✅ Fixed proxy template reference
- ✅ Fixed integration test field mismatch
- ✅ Fixed auth validation (200 only)
- ✅ Added test cleanup (Moodle + integration)
- ✅ Fixed core name sanitization (max 50 chars)
- ✅ Fixed version mapping (5.0.x support)
- ✅ Added stopwords.txt (EN + DE combined)
- ✅ Improved healthcheck (tests real API)
- ✅ Deployment attempt logging

### v1.3.1 (2025-11-01)
- ✅ Full idempotency - unlimited re-runs
- ✅ Selective password updates (zero downtime)
- ✅ Smart core name management
- ✅ Fixed host_vars duplicates
- ✅ Optimized codebase (52% reduction)

### v1.0.0 (2025-10-15)
- 🎉 Initial release

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test thoroughly
4. Run linters:
   ```bash
   ansible-lint tasks/*.yml
   yamllint .
   ```
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open Pull Request

---

## 👤 Author

**Bernd Schreistetter**
- Role: DevOps Engineer
- Organization: Eledia
- Email: bernd.schreistetter@eledia.de

---

## 🙏 Acknowledgments

- Apache Solr Team
- Moodle Community
- Ansible Community
- Docker Team

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourorg/ansible-role-solr/issues)
- **Documentation**: This README + review documents
- **Email**: support@eledia.de

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

---

**Made with ❤️ for the Ansible & Moodle communities**

**Production-tested** ✅ | **Fully documented** ✅ | **All bugs fixed** ✅
