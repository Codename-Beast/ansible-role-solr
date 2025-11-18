# PowerInit v1.7.0 - Backup & Deployment Flow

## 📋 Overview

PowerInit ist ein Init-Container, der **VOR** dem Solr-Start läuft und alle Konfigurationsdateien deployed.

**Version 1.7.0** fügt **SHA256 Checksum-Verifikation** hinzu um zu garantieren, dass immer die aktuelle security.json deployed wird.

Diese Dokumentation erklärt den kompletten Flow und wie Ansible und Docker Compose harmonisch zusammenarbeiten.

---

## 🔄 **COMPLETE FLOW**

### **Phase 1: Ansible Preparation (on Host)**

**Location:** `/opt/solr/config/` (Host-System)

```
┌─────────────────────────────────────────────┐
│  ANSIBLE (config_management.yml)           │
├─────────────────────────────────────────────┤
│  1. Generate security.json from template   │
│     - Uses passwords from host_vars        │
│     - Generates SHA256 hashes              │
│     - Creates /opt/solr/config/security.json
│                                             │
│  2. Generate other config files            │
│     - solrconfig.xml                       │
│     - moodle_schema.xml                    │
│     - stopwords.txt, synonyms.txt, etc.    │
└─────────────────────────────────────────────┘
                    ↓
    FILES READY ON HOST: /opt/solr/config/
```

### **Phase 2: PowerInit Execution (in Container)**

**Location:** `/var/solr/data/` (Container Volume)

```
┌─────────────────────────────────────────────────────┐
│  POWERINIT v1.7.0 (solr-init container)            │
├─────────────────────────────────────────────────────┤
│  [1/8] Install validation tools                    │
│        - jq, libxml2-utils, coreutils, sha256sum   │
│                                                     │
│  [2/8] 🔐 CHECKSUM VERIFICATION (NEW v1.7.0!)      │
│        ┌────────────────────────────────────┐     │
│        │ Calculate SHA256 checksums:        │     │
│        │   Source: /config/security.json    │     │
│        │   Deployed: /var/solr/data/        │     │
│        │                                     │     │
│        │ IF checksums MATCH:                │     │
│        │   → Skip deployment (already OK)   │     │
│        │   → Skip backup (no changes)       │     │
│        │                                     │     │
│        │ IF checksums DIFFER:               │     │
│        │   → FORCE_DEPLOY=true              │     │
│        │   → Continue with backup+deploy    │     │
│        └────────────────────────────────────┘     │
│                                                     │
│  [3/8] Create directories                          │
│        - /var/solr/data                            │
│        - /var/solr/data/configs                    │
│        - /var/solr/data/lang                       │
│        - /var/solr/data/old                        │
│                                                     │
│  [4/8] INTELLIGENT BACKUP ROTATION                 │
│        (Only if FORCE_DEPLOY=true!)                │
│        ┌──────────────────────────────────────┐   │
│        │ IF security.json exists:              │   │
│        │   1. Copy to /var/solr/data/old/     │   │
│        │      → security.json.TIMESTAMP        │   │
│        │                                       │   │
│        │   2. Count existing backups           │   │
│        │                                       │   │
│        │   3. IF > 3 backups:                  │   │
│        │      → Remove oldest                  │   │
│        │      → Keep 3 most recent            │   │
│        └──────────────────────────────────────┘   │
│                                                     │
│  [4.5/8] Backup other config files                 │
│          (Only if FORCE_DEPLOY=true!)              │
│          (solrconfig.xml, moodle_schema.xml, etc.) │
│          Same rotation policy: max 3 backups       │
│                                                     │
│  [5/8] VALIDATE config files                       │
│        - security.json (JSON syntax)               │
│        - solrconfig.xml (XML syntax)               │
│        - moodle_schema.xml (XML syntax)            │
│                                                     │
│  [6/8] DEPLOY FRESH configs from Ansible          │
│        (Only if FORCE_DEPLOY=true!)                │
│        Source: /config (mounted from host)         │
│        Target: /var/solr/data                      │
│        ┌────────────────────────────────────┐     │
│        │ /config/security.json              │     │
│        │        ↓                            │     │
│        │ /var/solr/data/security.json       │     │
│        │                                     │     │
│        │ THIS IS THE SOURCE OF TRUTH!       │     │
│        │ Always uses latest from Ansible    │     │
│        └────────────────────────────────────┘     │
│                                                     │
│  [7/8] Set permissions                             │
│        - chown 8983:8983                           │
│        - chmod 600 security.json                   │
│                                                     │
│  [8/8] 🔐 FINAL VERIFICATION (NEW v1.7.0!)         │
│        ┌────────────────────────────────────┐     │
│        │ Recalculate deployed checksum      │     │
│        │ Compare with source checksum       │     │
│        │                                     │     │
│        │ IF MATCH: ✅ SUCCESS               │     │
│        │ IF MISMATCH: ❌ EXIT 1 (FAIL)      │     │
│        │                                     │     │
│        │ This guarantees deployed version   │     │
│        │ is exactly what Ansible generated! │     │
│        └────────────────────────────────────┘     │
│        - Show active config                        │
│        - List backups (max 3)                      │
│        - Display deployment stats                  │
│        - Confirm checksum verification             │
└─────────────────────────────────────────────────────┘
                    ↓
          Solr container starts
```

---

## 📁 **FILE STRUCTURE**

### **On Host (after Ansible run)**
```
/opt/solr/config/
├── security.json          ← Generated by Ansible (SOURCE OF TRUTH)
├── solrconfig.xml
├── moodle_schema.xml
├── stopwords_de.txt
├── stopwords_en.txt
├── stopwords.txt
├── synonyms.txt
└── protwords.txt
```

### **In Container (after PowerInit)**
```
/var/solr/data/
├── security.json          ← Active config (from /config)
├── configs/
│   ├── solrconfig.xml
│   ├── moodle_schema.xml
│   ├── synonyms.txt
│   └── protwords.txt
├── lang/
│   ├── stopwords_de.txt
│   ├── stopwords_en.txt
│   └── stopwords.txt
└── old/                   ← NEW! Backup directory
    ├── security.json.20250117_172342  ← Backup 1 (newest)
    ├── security.json.20250117_143021  ← Backup 2
    ├── security.json.20250117_112505  ← Backup 3 (oldest kept)
    └── configs/
        ├── solrconfig.xml.20250117_172342
        ├── solrconfig.xml.20250117_143021
        └── solrconfig.xml.20250117_112505
```

---

## 🎯 **KEY FEATURES**

### ✅ **1. Single Source of Truth**
- **Ansible** generates all configs with current passwords
- **PowerInit** always deploys the latest from Ansible
- No conflicts, no overwrites

### ✅ **2. Intelligent Backup Rotation**
- Automatic backup before each deployment
- **Maximum 3 backups** kept
- Oldest backups automatically removed
- Timestamp-based naming for traceability

### ✅ **3. No Disk Space Issues**
- Old behavior: Unlimited backups → disk full
- New behavior: Max 3 backups → controlled disk usage

### ✅ **4. Easy Recovery**
```bash
# List available backups
docker exec solr_srhcampus ls -lh /var/solr/data/old/

# Restore from backup
docker exec solr_srhcampus cp \
  /var/solr/data/old/security.json.20250117_172342 \
  /var/solr/data/security.json

# Restart Solr
docker restart solr_srhcampus
```

---

## 🔧 **ANSIBLE ↔ DOCKER COORDINATION**

### **Ansible's Responsibilities:**
1. ✅ Generate security.json with correct password hashes
2. ✅ Write to `/opt/solr/config/` (host)
3. ✅ Validate structure (basic checks)
4. ✅ Calculate checksums

### **PowerInit's Responsibilities:**
1. ✅ Backup existing configs (max 3)
2. ✅ Validate syntax (JSON/XML)
3. ✅ Deploy fresh configs to container
4. ✅ Set correct permissions
5. ✅ Rotate backups automatically

### **Docker Volume Mount:**
```yaml
volumes:
  - /opt/solr/config:/config:ro  # Read-only! PowerInit can't modify
```

**Result:** PowerInit can NEVER modify Ansible's files → No conflicts!

---

## 📊 **BACKUP ROTATION ALGORITHM**

```bash
# Current file exists?
if [ -f /var/solr/data/security.json ]; then

  # 1. Create backup with timestamp
  cp security.json old/security.json.TIMESTAMP

  # 2. Count backups
  BACKUP_COUNT=$(ls -1 old/security.json.* | wc -l)

  # 3. If more than 3, remove oldest
  if [ $BACKUP_COUNT -gt 3 ]; then
    ls -1t old/security.json.* | tail -n +4 | xargs rm -f
  fi
fi

# 4. Deploy fresh file from Ansible
cp /config/security.json /var/solr/data/security.json
```

**Example Timeline:**
```
Run 1: No backups → Deploy → 0 backups
Run 2: Backup v1  → Deploy → 1 backup
Run 3: Backup v2  → Deploy → 2 backups
Run 4: Backup v3  → Deploy → 3 backups
Run 5: Backup v4  → Deploy → 3 backups (v1 deleted)
Run 6: Backup v5  → Deploy → 3 backups (v2 deleted)
```

---

## 🚫 **WHAT WILL NEVER HAPPEN**

❌ PowerInit modifying Ansible files (read-only mount)
❌ Unlimited backup accumulation (max 3 enforced)
❌ Ansible overwriting container files (different paths)
❌ Hash/password mismatches (Ansible is source of truth)
❌ Old security.json being deployed (always fresh)

---

## 🎉 **BENEFITS**

1. **Clear Separation of Concerns**
   - Ansible: Configuration generation
   - PowerInit: Deployment & backup

2. **Automatic Backup Rotation**
   - No manual cleanup needed
   - Always have last 3 versions

3. **Easy Debugging**
   - Check `/var/solr/data/old/` for recent changes
   - Compare timestamps with deployment logs

4. **Production-Safe**
   - No data loss (backups)
   - No disk space issues (rotation)
   - No configuration conflicts

---

## 🔍 **DEBUGGING**

### Check Current Config
```bash
docker exec solr_srhcampus cat /var/solr/data/security.json
```

### List Backups
```bash
docker exec solr_srhcampus ls -lah /var/solr/data/old/
```

### Compare Backup vs Current
```bash
# Get backup
docker exec solr_srhcampus cat /var/solr/data/old/security.json.20250117_172342 > backup.json

# Get current
docker exec solr_srhcampus cat /var/solr/data/security.json > current.json

# Compare
diff backup.json current.json
```

### View PowerInit Logs
```bash
docker logs solr_srhcampus_powerinit
```

---

## 📝 **VERSION HISTORY**

- **v1.6.0**: Intelligent backup rotation (max 3), moved to `/var/solr/data/old/`
- **v1.5.0**: Basic backup with timestamp
- **v1.4.0**: SSL awareness
- **v1.3.9**: Comment cleanup
- **v1.3.8**: Cache busting with Alpine 3.20

---

**Maintained by:** Eledia Operations Team
**Last Updated:** 2025-01-17
**PowerInit Version:** 1.6.0
