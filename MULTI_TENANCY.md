# Multi-Tenancy Guide

**Version**: 3.2.0
**Last Updated**: 2025-11-06

---

## Overview

This Solr Docker solution supports **optional multi-tenancy** for hosting multiple isolated search indexes (tenants) within a single Solr instance. Each tenant gets:

- ✅ **Dedicated Solr Core** - Isolated data storage
- ✅ **Dedicated User Account** - RBAC-enforced access control
- ✅ **Unique Credentials** - No shared passwords
- ✅ **Resource Monitoring** - Per-tenant metrics in Grafana
- ✅ **Independent Backups** - Per-tenant backup/restore

---

## Table of Contents

1. [When to Use Multi-Tenancy](#when-to-use-multi-tenancy)
2. [Architecture](#architecture)
3. [Security Isolation](#security-isolation)
4. [Tenant Management](#tenant-management)
5. [Naming Conventions](#naming-conventions)
6. [Migration Guide](#migration-guide)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## When to Use Multi-Tenancy

### ✅ Use Multi-Tenancy When:

- **Multiple Moodle Instances**: You run multiple Moodle sites on one server
- **Development/Staging/Production**: Separate environments on same infrastructure
- **Departmental Isolation**: Different departments need isolated search indexes
- **Cost Optimization**: Reduce resource overhead vs. multiple Solr containers
- **Centralized Management**: Single monitoring/backup stack for all tenants

### ❌ Use Single-Tenant (Default) When:

- **One Application**: Only one Moodle/application needs search
- **Maximum Isolation**: You need complete container-level separation
- **Simplicity**: You want minimal complexity
- **Different Solr Versions**: Tenants require different Solr versions

---

## Architecture

### Single-Tenant Mode (Default)

```
┌─────────────────────────────────────┐
│  Solr Container                     │
│  ┌───────────────────────────────┐  │
│  │  Core: "moodle"               │  │
│  │  User: "customer_user"        │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Usage**: Standard deployment, no special configuration required.

### Multi-Tenant Mode (Optional)

```
┌───────────────────────────────────────────────────────┐
│  Solr Container                                       │
│  ┌─────────────────┐  ┌─────────────────┐           │
│  │ Core: moodle_t1 │  │ Core: moodle_t2 │  ...      │
│  │ User: t1_customer│ │ User: t2_customer│           │
│  └─────────────────┘  └─────────────────┘           │
│                                                       │
│  Admin User: Has access to ALL cores                 │
└───────────────────────────────────────────────────────┘
```

**Usage**: Enable via tenant management scripts (see below).

---

## Security Isolation

### RBAC (Role-Based Access Control)

Each tenant is completely isolated through Solr's built-in RBAC:

```json
{
  "authentication": {
    "blockUnknown": true,
    "class": "solr.BasicAuthPlugin",
    "credentials": {
      "admin_user": "SHA256:...",
      "t1_customer": "SHA256:...",
      "t2_customer": "SHA256:..."
    }
  },
  "authorization": {
    "class": "solr.RuleBasedAuthorizationPlugin",
    "user-role": {
      "admin_user": ["admin"],
      "t1_customer": ["tenant1_role"],
      "t2_customer": ["tenant2_role"]
    },
    "permissions": [
      {
        "name": "tenant1-access",
        "role": "tenant1_role",
        "collection": "moodle_t1"
      },
      {
        "name": "tenant2-access",
        "role": "tenant2_role",
        "collection": "moodle_t2"
      }
    ]
  }
}
```

### Isolation Guarantees

- ✅ **No Cross-Tenant Queries**: `t1_customer` cannot query `moodle_t2`
- ✅ **No Schema Access**: Tenants cannot modify other tenants' schemas
- ✅ **No Admin Operations**: Tenants cannot delete/create cores
- ✅ **Admin Oversight**: `admin_user` retains full access for management

---

## Tenant Management

### Create a New Tenant

```bash
make tenant-create TENANT=tenant1
```

**What happens:**
1. Creates Solr core: `moodle_tenant1`
2. Creates user: `tenant1_customer` with random secure password
3. Configures RBAC for isolation
4. Saves credentials to `.env.tenant1`
5. Validates creation with test query

**Output:**
```
✅ Tenant 'tenant1' created successfully!

📋 Connection Details:
   Core:     moodle_tenant1
   User:     tenant1_customer
   Password: <random-secure-password>
   URL:      http://localhost:8983/solr/moodle_tenant1

🔐 Credentials saved to: .env.tenant1
```

### List All Tenants

```bash
make tenant-list
```

**Output:**
```
📋 Active Tenants:

Tenant ID    Core Name        User Account       Documents    Size (MB)    Status
-----------  ---------------  -----------------  -----------  -----------  --------
tenant1      moodle_tenant1   tenant1_customer   1,234        45.2         ✅ Active
tenant2      moodle_tenant2   tenant2_customer   5,678        123.4        ✅ Active
```

### Delete a Tenant

**With backup (recommended):**
```bash
make tenant-delete TENANT=tenant1 BACKUP=true
```

**Without backup:**
```bash
make tenant-delete TENANT=tenant1
```

**What happens:**
1. Creates backup snapshot (if `BACKUP=true`)
2. Unloads and deletes Solr core
3. Removes user from security.json
4. Cleans up data directory
5. Archives credentials file

### Backup a Tenant

**Single tenant:**
```bash
make tenant-backup TENANT=tenant1
```

**All tenants:**
```bash
make tenant-backup-all
```

**Backup location:** `backups/tenant_<name>_<timestamp>.tar.gz`

---

## Naming Conventions

### Core Names

- **Format**: `moodle_<tenant_id>`
- **Examples**: `moodle_tenant1`, `moodle_prod`, `moodle_dept_hr`
- **Rules**:
  - Lowercase only
  - Use underscores (not hyphens)
  - Max 50 characters

### User Names

- **Format**: `<tenant_id>_customer`
- **Examples**: `tenant1_customer`, `prod_customer`, `dept_hr_customer`
- **Rules**:
  - Match tenant_id from core name
  - Always suffix with `_customer`
  - Lowercase only

### Environment Files

- **Format**: `.env.<tenant_id>`
- **Examples**: `.env.tenant1`, `.env.prod`
- **Content**:
  ```bash
  TENANT_ID=tenant1
  TENANT_CORE=moodle_tenant1
  TENANT_USER=tenant1_customer
  TENANT_PASSWORD=<generated-password>
  TENANT_URL=http://localhost:8983/solr/moodle_tenant1
  ```

---

## Migration Guide

### Migrating from Single-Tenant to Multi-Tenant

**Step 1: Backup existing data**
```bash
make backup
```

**Step 2: Create first tenant from existing core**
```bash
# Option A: Rename existing core
docker exec -it solr_solr_1 solr stop -p 8983
# Manually rename data/moodle to data/moodle_tenant1
# Update security.json

# Option B: Create new tenant and migrate data
make tenant-create TENANT=tenant1
# Use Solr's index replication or export/import
```

**Step 3: Update application configuration**
```bash
# In your Moodle config.php:
$CFG->solr_server_hostname = 'localhost';
$CFG->solr_server_port = '8983';
$CFG->solr_indexname = 'moodle_tenant1';  # Changed from 'moodle'
$CFG->solr_server_username = 'tenant1_customer';
$CFG->solr_server_password = '<from .env.tenant1>';
```

**Step 4: Test connection**
```bash
curl -u tenant1_customer:<password> \
  'http://localhost:8983/solr/moodle_tenant1/select?q=*:*'
```

### Migrating from Multi-Tenant to Single-Tenant

**Step 1: Export tenant data**
```bash
make tenant-backup TENANT=tenant1
```

**Step 2: Deploy new single-tenant instance**
```bash
# In new directory or server:
git clone <repo>
make init
make start
make create-core  # Creates default 'moodle' core
```

**Step 3: Import data**
```bash
# Extract backup and use Solr import tools
# Or use index replication
```

---

## Best Practices

### 1. Capacity Planning

**Rule of thumb:** 10-15 tenants per 16GB RAM Solr instance.

**Calculate tenant capacity:**
```bash
# Average index size per tenant
AVG_INDEX_SIZE_GB=2

# Available disk space
AVAILABLE_DISK_GB=100

# Max tenants (with 50% headroom)
MAX_TENANTS=$((AVAILABLE_DISK_GB / AVG_INDEX_SIZE_GB / 2))
# Result: ~25 tenants
```

### 2. Naming Strategy

**Use meaningful tenant IDs:**
- ✅ Good: `prod`, `staging`, `dept_marketing`, `school_main`
- ❌ Bad: `t1`, `test123`, `core1`

**Document tenant ownership:**
```bash
# Create a tenant registry
cat > tenants.yml <<EOF
tenants:
  - id: prod
    owner: admin@example.com
    purpose: Production Moodle site
    created: 2025-11-06
  - id: staging
    owner: dev@example.com
    purpose: Staging environment
    created: 2025-11-06
EOF
```

### 3. Password Management

**Store credentials securely:**
```bash
# Use a password manager or secrets vault
# Avoid committing .env.* files to git

# Add to .gitignore:
echo ".env.*" >> .gitignore

# Use environment-specific vaults:
# - Production: HashiCorp Vault, AWS Secrets Manager
# - Development: 1Password, Bitwarden
```

### 4. Monitoring

**Set up per-tenant alerts:**
```bash
# In Grafana, create alerts for:
# - Query latency > 500ms per core
# - Index size growth > 20% per week
# - Error rate > 1% per tenant
```

### 5. Backup Strategy

**Automated tenant backups:**
```bash
# Add to crontab:
0 2 * * * cd /path/to/solr && make tenant-backup-all >> logs/backup.log 2>&1
```

**Retention policy:**
- Daily backups: 7 days
- Weekly backups: 4 weeks
- Monthly backups: 12 months

### 6. Resource Limits

**Monitor per-core metrics:**
```bash
# Check core sizes
docker exec solr_solr_1 du -sh /var/solr/data/moodle_*

# Check query rates
curl -u admin:password 'http://localhost:8983/solr/admin/metrics' | \
  jq '.metrics."solr.core.moodle_tenant1"'
```

**Set soft limits in Moodle:**
```php
// Limit max results per query
$CFG->solr_maxresults = 1000;

// Disable expensive features if needed
$CFG->solr_enable_file_indexing = false;
```

---

## Troubleshooting

### Tenant Creation Fails

**Error:** `Core already exists`
```bash
# Check existing cores
make tenant-list

# Delete old core if needed
make tenant-delete TENANT=<name>
```

**Error:** `Permission denied`
```bash
# Fix ownership
sudo chown -R 8983:8983 data/ logs/
```

### Tenant Cannot Access Core

**Error:** `HTTP 401 Unauthorized`
```bash
# Verify credentials
source .env.tenant1
curl -u "$TENANT_USER:$TENANT_PASSWORD" "$TENANT_URL/select?q=*:*"

# Check RBAC configuration
docker exec solr_solr_1 cat /var/solr/data/security.json | jq '.authorization.permissions'
```

**Error:** `HTTP 403 Forbidden`
```bash
# Verify role assignment
docker exec solr_solr_1 cat /var/solr/data/security.json | jq '.authorization."user-role"'

# Ensure tenant role has access to correct collection
```

### Performance Degradation with Multiple Tenants

**Symptoms:** Slow queries across all tenants

**Diagnosis:**
```bash
# Check JVM memory
curl -u admin:password 'http://localhost:8983/solr/admin/info/system' | \
  jq '.jvm.memory'

# Check per-core cache hit rates
curl -u admin:password 'http://localhost:8983/solr/admin/metrics' | \
  jq '.metrics | to_entries[] | select(.key | contains("CACHE")) | .value'
```

**Solutions:**
1. Increase heap size (maintain 50-60% of total memory)
2. Optimize cache sizes per tenant
3. Consider scaling horizontally (add more Solr instances)
4. Archive inactive tenants

### Cross-Tenant Data Leakage Concerns

**Verification test:**
```bash
# Try to access tenant2's core with tenant1's credentials
curl -u tenant1_customer:<password> \
  'http://localhost:8983/solr/moodle_tenant2/select?q=*:*'

# Expected: HTTP 403 Forbidden
```

**Audit RBAC configuration:**
```bash
./scripts/tenant-audit.sh  # (To be created in future version)
```

---

## Related Documentation

- [README.md](README.md) - Main documentation
- [RUNBOOK.md](RUNBOOK.md) - Operational procedures
- [MEMORY_TUNING.md](MEMORY_TUNING.md) - Performance tuning
- [SECURITY.md](SECURITY.md) - Security best practices

---

## Support

**Found a bug?** Report at: https://github.com/Codename-Beast/ansible-role-solr/issues
**Questions?** Check the [Troubleshooting](#troubleshooting) section above.

---

**Version**: 3.2.0
**License**: MIT
**Maintained by**: Codename-Beast
