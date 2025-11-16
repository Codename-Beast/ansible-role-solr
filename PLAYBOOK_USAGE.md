# Playbook Usage Guide - v38

## Ihr Playbook-Setup

```yaml
- name: Install Solr
  hosts: "{{ hosts }}"
  gather_facts: yes
  become: yes

  pre_tasks:
    - name: Validate 'hosts' variable is provided
      fail:
        msg: "'hosts' must be defined using -e 'hosts=yourtargethost'"
      when: hosts is not defined or hosts == ""

  roles:
    - role: install-solr
```

---

## 📋 Vollständige Installation

### 1. Basis-Installation (komplett)

```bash
ansible-playbook site.yml -e 'hosts=yourserver'
```

**Was passiert:**
- ✅ System-Vorbereitung (Docker, Verzeichnisse)
- ✅ Solr Container-Deployment (6GB Heap, 12GB total)
- ✅ Core-Erstellung mit Classic Schema
- ✅ Authentication (admin, support, moodle users)
- ✅ Apache Reverse Proxy
- ✅ Integration Tests

**Dauer:** ~5-10 Minuten

---

## 👥 User Management (Multi-Tenant)

### 2. Users während Installation hinzufügen

**host_vars/yourserver.yml:**
```yaml
solr_additional_users:
  - username: "tenant1_admin"
    password: "SecurePassword123!"
    roles: ["core-admin-tenant1_core"]

  - username: "tenant2_readonly"
    password: "ReadOnlyPass456!"
    roles: ["support"]

  - username: "api_user"
    password: "ApiKey789!"
    # Default role: core-admin-<core_name>
```

**Deployment:**
```bash
ansible-playbook site.yml -e 'hosts=yourserver' --tags=install-solr-users
```

**Downtime:** Ja (Container-Restart erforderlich)

---

### 3. Users on-the-fly hinzufügen (ZERO DOWNTIME) ⚡

**Scenario:** Neuer Kunde/Tenant benötigt Zugriff

**1. Edit host_vars/yourserver.yml:**
```yaml
solr_additional_users:
  - username: "new_tenant"
    password: "NewTenantPass2024!"
    roles: ["core-admin-new_tenant_core"]
```

**2. Hot-Reload (KEINE Downtime):**
```bash
# Option 1: Professional tag
ansible-playbook site.yml -e 'hosts=yourserver' --tags=solr-auth-reload

# Option 2: Alias
ansible-playbook site.yml -e 'hosts=yourserver' --tags=solr-users-hotupdate
```

**Ergebnis:**
- ✅ User sofort verfügbar (0 Sekunden Downtime!)
- ✅ Keine Container-Unterbrechung
- ✅ Produktionsverkehr ungestört

**Use Cases:**
- Neuer Mandant onboarden
- Passwort-Reset (Sicherheitsvorfall)
- Temporärer Support-Zugang
- Rechte-Anpassung

---

## 🔒 Passwort-Rotation (Zero-Downtime)

**Scenario:** Regelmäßige Passwort-Rotation alle 90 Tage

**1. Neue Passwörter in host_vars definieren:**
```yaml
solr_additional_users:
  - username: "tenant1_admin"
    password: "NewRotatedPassword123!"  # <-- Geändert
    roles: ["core-admin-tenant1_core"]
```

**2. Live-Update:**
```bash
ansible-playbook site.yml -e 'hosts=yourserver' --tags=solr-auth-reload
```

**3. User kann SOFORT mit neuem Passwort einloggen!**

---

## 🧪 Tests ausführen

### 4. Nur Tests (nach Änderungen)

```bash
ansible-playbook site.yml -e 'hosts=yourserver' --tags=install-solr-test
```

**Tests umfassen:**
- Container-Status
- Solr-Healthcheck
- Authentication (alle User)
- Core-Verfügbarkeit
- Proxy-Konfiguration
- Moodle-Schema Validierung (wenn aktiviert)

---

## 🔧 Granulare Tag-Nutzung

### 5. Nur bestimmte Komponenten deployen

```bash
# Nur Docker installieren
ansible-playbook site.yml -e 'hosts=yourserver' --tags=install-solr-docker

# Nur Auth neu konfigurieren
ansible-playbook site.yml -e 'hosts=yourserver' --tags=install-solr-auth

# Nur Proxy neu konfigurieren
ansible-playbook site.yml -e 'hosts=yourserver' --tags=install-solr-proxy

# Nur Core neu erstellen
ansible-playbook site.yml -e 'hosts=yourserver' --tags=install-solr-core

# Nur Container neu deployen
ansible-playbook site.yml -e 'hosts=yourserver' --tags=install-solr-deployment
```

---

## 🎯 Praktische Beispiele

### Beispiel 1: Multi-Tenant SaaS Setup

**host_vars/production-solr.yml:**
```yaml
solr_app_domain: "solr.mycompany.com"
solr_core_name: "main_search"

solr_additional_users:
  # Kunde 1
  - username: "customer_abc"
    password: "!vault |
              $ANSIBLE_VAULT;1.1;AES256..."
    roles: ["core-admin-customer_abc_core"]

  # Kunde 2
  - username: "customer_xyz"
    password: "!vault |
              $ANSIBLE_VAULT;1.1;AES256..."
    roles: ["core-admin-customer_xyz_core"]

  # Support Team
  - username: "support_team"
    password: "!vault |
              $ANSIBLE_VAULT;1.1;AES256..."
    roles: ["support"]  # Read-only

  # Monitoring
  - username: "prometheus"
    password: "!vault |
              $ANSIBLE_VAULT;1.1;AES256..."
    roles: ["monitoring"]
```

**Deployment:**
```bash
# Initialer Rollout
ansible-playbook site.yml -e 'hosts=production-solr' --ask-vault-pass

# Neuer Kunde hinzufügen (später)
ansible-playbook site.yml -e 'hosts=production-solr' --tags=solr-auth-reload --ask-vault-pass
```

---

### Beispiel 2: Moodle-Integration

**host_vars/moodle-solr.yml:**
```yaml
solr_app_domain: "search.school.edu"
solr_use_moodle_schema: true
solr_core_name: "moodle_courses"

# Moodle Plugin User (bereits vordefiniert)
solr_moodle_user: "moodle"
solr_moodle_password: "!vault | ..."

# Zusätzliche Test-User
solr_additional_users:
  - username: "dev_testing"
    password: "DevPass123!"
    roles: ["core-admin-moodle_courses"]
```

**Deployment:**
```bash
ansible-playbook site.yml -e 'hosts=moodle-solr' --ask-vault-pass
```

**Moodle Plugin Config:**
- URL: `https://search.school.edu/solr-admin/`
- Core: `moodle_courses`
- User: `moodle`
- Password: `<from vault>`

---

### Beispiel 3: Development → Production

**Development:**
```bash
# Dev-Server (ohne Vault)
ansible-playbook site.yml -e 'hosts=dev-solr' --limit=dev-solr
```

**Staging:**
```bash
# Staging mit Tests
ansible-playbook site.yml -e 'hosts=staging-solr' --tags=install-solr-test
```

**Production:**
```bash
# Prod-Deployment (mit Vault)
ansible-playbook site.yml -e 'hosts=prod-solr' --ask-vault-pass

# User-Update (Zero-Downtime)
ansible-playbook site.yml -e 'hosts=prod-solr' --tags=solr-auth-reload --ask-vault-pass
```

---

## 🔐 Security Best Practices

### Ansible Vault für Passwörter

**1. Passwort verschlüsseln:**
```bash
ansible-vault encrypt_string 'MySecurePassword123!' --name 'password'
```

**2. In host_vars nutzen:**
```yaml
solr_additional_users:
  - username: "prod_user"
    password: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      66386439653737623265326336363339643338373934636330313536353662633466366438373736
      6563306638383035356164316134346566383230343339310a363861633231646237303035636363
      35373034343334333733326336643732313263386165303233373837313639323434636264366461
      3062343032323435320a363030333039633338323661306533373366396561633130643564373839
      3339
    roles: ["core-admin-prod_core"]
```

**3. Deployment mit Vault:**
```bash
ansible-playbook site.yml -e 'hosts=prod' --ask-vault-pass
```

---

### Passwort-Richtlinien

**Empfohlene Policy:**
```yaml
# Minimum 16 Zeichen
# Mix: Groß-, Kleinbuchstaben, Zahlen, Symbole
# Beispiel: "K9$mPq#2vL!xR7@wN4"

solr_additional_users:
  - username: "high_security_user"
    password: "K9$mPq#2vL!xR7@wN4yT5&"  # 24 chars
    roles: ["admin"]
```

---

## 🚀 Performance (16GB Server)

Ihre aktuelle Konfiguration (optimiert in v38):

```yaml
# defaults/main.yml (bereits gesetzt)
solr_heap_size: "6g"              # JVM Heap
solr_memory_limit: "12g"          # Docker Limit (Heap + Off-Heap)
solr_memory_swap: "12g"           # Swap Limit
solr_memory_reservation: "10g"    # Garantierte Reservation
solr_cpu_count: "4"               # CPU Cores

# GC Tuning (G1GC für 6GB Heap)
solr_gc_options: |
  -XX:+UseG1GC
  -XX:+ParallelRefProcEnabled
  -XX:G1HeapRegionSize=16m
  -XX:MaxGCPauseMillis=200
  -XX:InitiatingHeapOccupancyPercent=45
```

**Memory-Aufteilung (16GB Server):**
- Solr Heap: 6 GB (JVM)
- Solr Off-Heap: 6 GB (Lucene Index Cache)
- OS + Buffer: 4 GB (wie gewünscht: ~2GB + Reserve)

---

## 📊 Monitoring & Troubleshooting

### Container-Status prüfen

```bash
# Status
docker ps -f name=solr

# Logs
docker logs solr-production --tail=100 -f

# Resource Usage
docker stats solr-production

# Health
curl -u admin:password http://localhost:8983/solr/admin/ping
```

### Auth-Tests

```bash
# Admin-User testen
curl -u admin:yourpass http://localhost:8983/solr/admin/cores?action=STATUS

# Tenant-User testen
curl -u tenant1:tenantpass http://localhost:8983/solr/tenant1_core/select?q=*:*

# Support-User (read-only)
curl -u support:supportpass http://localhost:8983/solr/admin/ping
```

### Logs-Analyse

```bash
# GC Logs (Performance)
docker exec solr-production tail -f /var/solr/logs/solr_gc.log

# Solr Logs (Errors)
docker exec solr-production tail -f /var/solr/logs/solr.log

# Auth-Events
docker logs solr-production 2>&1 | grep -i "authentication"
```

---

## 🎓 Tag-Referenz (v38)

| Tag | Beschreibung | Downtime? | Use Case |
|-----|--------------|-----------|----------|
| *(keine)* | Vollständige Installation | Ja | Initial Deployment |
| `install-solr-users` | User während Installation | Ja | Setup mit Users |
| `solr-users-deploy` | User deploy mit Config-Generation | Ja | User + Config ändern |
| `solr-auth-reload` | **Hot-reload Users (Zero-Downtime)** | **Nein** ⚡ | Prod User-Updates |
| `solr-users-hotupdate` | Alias für solr-auth-reload | Nein ⚡ | Prod User-Updates |
| `install-solr-test` | Nur Tests ausführen | Nein | Validierung |
| `install-solr-docker` | Nur Docker installieren | Nein | Docker-Setup |
| `install-solr-auth` | Auth neu konfigurieren | Ja | Auth-Änderungen |
| `install-solr-proxy` | Proxy neu konfigurieren | Nein | Proxy-Updates |
| `install-solr-core` | Core neu erstellen | Ja | Core-Änderungen |

---

## 💡 Pro-Tipps

### 1. Limit für einzelne Hosts

```bash
# Nur einen Host aus Inventory
ansible-playbook site.yml -e 'hosts=all' --limit=specific-server
```

### 2. Dry-Run (Check Mode)

```bash
# Änderungen prüfen ohne Apply
ansible-playbook site.yml -e 'hosts=prod' --check --diff
```

### 3. Verbose Output (Debugging)

```bash
# Debug-Level
ansible-playbook site.yml -e 'hosts=dev' -vvv
```

### 4. Conditional User Updates

```bash
# Nur wenn neue Users definiert sind
ansible-playbook site.yml -e 'hosts=prod' --tags=solr-auth-reload \
  --extra-vars='{"solr_additional_users": [{"username": "new_user", "password": "pass", "roles": ["support"]}]}'
```

---

## 🎯 Quick Reference

```bash
# Initial Setup
ansible-playbook site.yml -e 'hosts=myserver'

# Add User (Zero-Downtime)
ansible-playbook site.yml -e 'hosts=myserver' --tags=solr-auth-reload

# Run Tests
ansible-playbook site.yml -e 'hosts=myserver' --tags=install-solr-test

# Update Proxy
ansible-playbook site.yml -e 'hosts=myserver' --tags=install-solr-proxy

# Full Re-Deploy
ansible-playbook site.yml -e 'hosts=myserver'
```

---

## 📚 Weitere Dokumentation

- **USER_MANAGEMENT.md** - Detaillierte User-Management Anleitung
- **DEPLOYMENT_GUIDE.md** - Deployment Best Practices
- **TASK_STRUCTURE_ANALYSIS.md** - Architektur-Analyse
- **README.md** - Vollständige Feature-Liste

---

## ✅ v38 Features Zusammenfassung

1. ✅ **Multi-Tenant User Management** - Per-Core Rollen
2. ✅ **Zero-Downtime Updates** - Hot-Reload via API
3. ✅ **16GB Server Optimized** - 6GB Heap + 6GB Off-Heap
4. ✅ **Classic Schema** - Fixed Schema für Moodle
5. ✅ **Professional Tags** - `solr-auth-reload` + Alias
6. ✅ **Security Hardening** - Double SHA256, Vault Support
7. ✅ **Proxy Configuration** - HTTPS + Security Headers
8. ✅ **Comprehensive Tests** - Integration + Moodle Tests

**Branch:** `claude/create-branch-v38-01Q1rF7wvFgf6Jnp9FKB1WGT`
**Status:** ✅ Production Ready

---

**Happy Deploying! 🚀**
