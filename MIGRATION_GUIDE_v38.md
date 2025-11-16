# Migration Guide: v37 → v38

## 🔄 Wichtige Änderungen (Breaking Changes)

### 1. Variable Umbenennungen

| Alt (v37) | Neu (v38) | Grund |
|-----------|-----------|-------|
| `moodle_app_domain` | `solr_app_domain` | Generischer - Solr ist nicht nur für Moodle |
| `solr_customer_user` | `solr_moodle_user` | Semantisch korrekter |
| `solr_customer_password` | `solr_moodle_password` | Semantisch korrekter |

### 2. Neue Features (Optional)

- **Multi-Tenant User Management** via `solr_additional_users`
- **Zero-Downtime Updates** via `--tags=solr-auth-reload`
- **16GB Memory Optimization** (6GB Heap + 6GB Off-Heap)
- **Classic Schema** für Moodle (statt Managed Schema)

---

## 📋 Schritt-für-Schritt Migration

### Ihre Alte Config (v37):

```yaml
system_type:
  - DBMS
  - Solr

moodle_app_domain: 'srh-ecampus.de.solr.elearning-home.de'  # ❌ ALT

solr_port: 8983
solr_core_name: "srhecampusdesolr_core"
solr_container_name: "hc-srhecampusdesolr"
solr_auth_enabled: true
solr_admin_user: "admin"
solr_admin_password: '!hj0iuoefeufhefuj!'
solr_support_user: "support"
solr_support_password: '!hj0iuoefeufhefuj!'
solr_customer_password: "efr!ojF!feiXjfeFoj"  # ❌ ALT
```

### Neue Config (v38) - Minimale Änderungen:

```yaml
system_type:
  - DBMS
  - Solr

solr_app_domain: 'srh-ecampus.de.solr.elearning-home.de'  # ✅ NEU

solr_port: 8983
solr_core_name: "srhecampusdesolr_core"
solr_container_name: "hc-srhecampusdesolr"
solr_auth_enabled: true
solr_admin_user: "admin"
solr_admin_password: '!hj0iuoefeufhefuj!'
solr_support_user: "support"
solr_support_password: '!hj0iuoefeufhefuj!'
solr_moodle_user: "moodle"  # ✅ NEU (explizit definiert)
solr_moodle_password: "efr!ojF!feiXjfeFoj"  # ✅ NEU
```

### Neue Config (v38) - Mit allen Optimierungen:

```yaml
system_type:
  - DBMS
  - Solr

#######################################################################
# CORE CONFIGURATION
#######################################################################
solr_app_domain: "srh-ecampus.de.solr.elearning-home.de"
solr_port: 8983
solr_core_name: "srhecampus"  # ✅ Kürzer (empfohlen max 10 Zeichen)
solr_container_name: "hc-srhecampus-solr"
solr_version: "9.9.0"

#######################################################################
# AUTHENTICATION
#######################################################################
solr_auth_enabled: true
solr_admin_user: "admin"
solr_admin_password: "!hj0iuoefeufhefuj!"  # TODO: Vault nutzen!
solr_support_user: "support"
solr_support_password: "!hj0iuoefeufhefuj!"  # TODO: Vault nutzen!
solr_moodle_user: "moodle"
solr_moodle_password: "efr!ojF!feiXjfeFoj"  # TODO: Vault nutzen!

#######################################################################
# MEMORY OPTIMIZATION (16GB Server)
#######################################################################
solr_heap_size: "6g"
solr_memory_limit: "12g"
solr_memory_swap: "12g"
solr_memory_reservation: "10g"
solr_cpu_count: "4"

#######################################################################
# MOODLE INTEGRATION
#######################################################################
solr_use_moodle_schema: true
solr_schema_factory: "ClassicIndexSchemaFactory"

#######################################################################
# PROXY CONFIGURATION
#######################################################################
solr_proxy_enabled: true
solr_proxy_path: "/solr-admin"
solr_restrict_admin: true
solr_admin_allowed_ips:
  - "127.0.0.1"
  - "::1"
  # Fügen Sie hier Ihre IPs hinzu
```

---

## 🚀 Migrations-Schritte

### 1. Backup erstellen

```bash
# Config sichern
cp host_vars/srh-ecampus-solr.yml host_vars/srh-ecampus-solr.yml.backup

# Daten sichern (falls Solr schon läuft)
ansible-playbook backup-playbook.yml -e 'hosts=srh-ecampus-solr'
```

### 2. Host_vars aktualisieren

**Option A: Minimal-Migration (nur Pflicht-Änderungen)**

```bash
# Alte Variablen umbenennen
sed -i 's/moodle_app_domain/solr_app_domain/g' host_vars/srh-ecampus-solr.yml
sed -i 's/solr_customer_password/solr_moodle_password/g' host_vars/srh-ecampus-solr.yml

# Moodle User explizit definieren (falls nicht vorhanden)
echo 'solr_moodle_user: "moodle"' >> host_vars/srh-ecampus-solr.yml
```

**Option B: Vollständige Migration (empfohlen)**

```bash
# Neue Template-Datei nutzen
cp host_vars_example_v38.yml host_vars/srh-ecampus-solr.yml

# Ihre alten Passwörter eintragen
# MANUELL editieren: solr_admin_password, solr_support_password, solr_moodle_password
```

### 3. Ansible Vault einrichten (WICHTIG für Production!)

```bash
# Passwörter verschlüsseln
ansible-vault encrypt_string '!hj0iuoefeufhefuj!' --name 'solr_admin_password'
# Output kopieren und in host_vars einfügen

ansible-vault encrypt_string '!hj0iuoefeufhefuj!' --name 'solr_support_password'
ansible-vault encrypt_string 'efr!ojF!feiXjfeFoj' --name 'solr_moodle_password'
```

**Beispiel mit Vault:**

```yaml
solr_admin_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  66386439653737623265326336363339643338373934636330313536353662633466366438373736
  3563306638383035356164316134346566383230343339310a363861633231646237303035636363
  ...
```

### 4. Validierung (Dry-Run)

```bash
# Check Mode (keine Änderungen)
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --check --diff

# Nur Preflight Checks
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --tags=install-solr-preflight
```

### 5. Deployment (v38)

**Wenn Solr NICHT läuft (erste Installation):**

```bash
# Vollständige Installation
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr'
```

**Wenn Solr BEREITS läuft (Update):**

```bash
# Option 1: Vollständiges Re-Deployment (mit Downtime)
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr'

# Option 2: Nur Auth-Update (Zero-Downtime) - falls nur User geändert
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --tags=solr-auth-reload
```

### 6. Validierung nach Migration

```bash
# Integration Tests
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --tags=install-solr-test

# Manueller Test
curl -u admin:!hj0iuoefeufhefuj! \
  http://srh-ecampus.de.solr.elearning-home.de:8983/solr/admin/ping

# Container Status
ssh srh-ecampus-solr "docker ps | grep solr"
ssh srh-ecampus-solr "docker logs hc-srhecampus-solr --tail=50"
```

---

## 🎯 Neue Features nutzen

### Multi-Tenant User Management

**1. User in host_vars definieren:**

```yaml
solr_additional_users:
  # Developer
  - username: "dev_team"
    password: "DevPass123!"
    roles: ["core-admin-srhecampus"]

  # Monitoring
  - username: "prometheus"
    password: "MonitorPass456!"
    roles: ["support"]
```

**2. Hot-Reload (Zero-Downtime!):**

```bash
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --tags=solr-auth-reload
```

**3. User testen:**

```bash
curl -u dev_team:DevPass123! \
  http://srh-ecampus.de.solr.elearning-home.de:8983/solr/admin/cores?action=STATUS
```

---

## 🔍 Troubleshooting

### Problem: "Variable not defined" Fehler

**Lösung:** Alte Variablen wurden umbenannt

```bash
# Prüfen Sie Ihre host_vars:
grep -E "moodle_app_domain|solr_customer" host_vars/srh-ecampus-solr.yml

# Falls vorhanden → umbenennen:
sed -i 's/moodle_app_domain/solr_app_domain/g' host_vars/srh-ecampus-solr.yml
sed -i 's/solr_customer_password/solr_moodle_password/g' host_vars/srh-ecampus-solr.yml
```

### Problem: Container startet nicht nach Migration

**Lösung:** Config-Dateien prüfen

```bash
# Security.json Syntax prüfen
ssh srh-ecampus-solr "jq . /opt/solr/config/security.json"

# Container Logs
ssh srh-ecampus-solr "docker logs hc-srhecampus-solr"

# Force Rebuild
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' -e 'force_container_rebuild=true'
```

### Problem: Authentication schlägt fehl

**Lösung:** Passwort-Hashes neu generieren

```bash
# Auth-Management neu ausführen
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --tags=install-solr-auth

# Oder: Container neu deployen
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --tags=install-solr-deployment
```

---

## ✅ Migrations-Checkliste

- [ ] **Backup erstellt** (host_vars + Solr-Daten)
- [ ] **Variablen umbenannt** (moodle_app_domain → solr_app_domain)
- [ ] **Moodle-Password angepasst** (solr_customer_password → solr_moodle_password)
- [ ] **Memory-Config aktualisiert** (6GB Heap für 16GB Server)
- [ ] **Vault eingerichtet** (Passwörter verschlüsselt)
- [ ] **Dry-Run erfolgreich** (--check --diff)
- [ ] **Deployment ausgeführt** (ansible-playbook site.yml)
- [ ] **Tests bestanden** (--tags=install-solr-test)
- [ ] **Manueller Test** (curl mit allen Usern)
- [ ] **Container läuft** (docker ps)
- [ ] **Logs sauber** (keine Errors in docker logs)
- [ ] **Proxy funktioniert** (https://domain/solr-admin/)
- [ ] **Moodle-Connection OK** (Moodle Search Plugin verbindet)
- [ ] **Monitoring eingerichtet** (optional)
- [ ] **Backup-Strategy aktiviert** (optional)
- [ ] **Dokumentation aktualisiert**

---

## 📊 Vergleich: Alt vs. Neu

| Feature | v37 | v38 |
|---------|-----|-----|
| **Variable Namen** | moodle_app_domain | solr_app_domain ✅ |
| **User Management** | Nur admin/support/customer | + Multi-Tenant Users ✅ |
| **User Updates** | Container-Restart nötig | Zero-Downtime Hot-Reload ✅ |
| **Memory** | 2GB Heap (default) | 6GB Heap + 6GB Off-Heap ✅ |
| **Schema** | Managed Schema | Classic Schema ✅ |
| **Health Check** | 401 Error Bug | Behoben ✅ |
| **docker_container_info** | Bug (Python SDK fehlt) | Behoben (docker inspect) ✅ |
| **Tags** | solr-users-live | solr-auth-reload ✅ |
| **Proxy** | ProxyPass Bug | Behoben (nocanon) ✅ |
| **Task-Struktur** | 23 Dateien | Optimiert analysiert ✅ |

---

## 🎓 Best Practices nach Migration

### 1. Passwort-Rotation einrichten

```bash
# Alle 90 Tage
ansible-playbook site.yml -e 'hosts=srh-ecampus-solr' --tags=solr-auth-reload
```

### 2. Monitoring aktivieren

```yaml
# host_vars ergänzen:
solr_additional_users:
  - username: "prometheus"
    password: "{{ vault_prometheus_password }}"
    roles: ["support"]
```

### 3. Backup automatisieren

```yaml
# Uncomment in host_vars:
solr_backup_enabled: true
solr_backup_schedule: "0 2 * * *"  # Täglich 2 Uhr
solr_backup_retention_days: 7
```

### 4. Multi-Tenant Setup

```yaml
# Pro Mandant ein User:
solr_additional_users:
  - username: "tenant_srh"
    password: "{{ vault_tenant_srh_pass }}"
    roles: ["core-admin-srhecampus"]

  - username: "tenant_xyz"
    password: "{{ vault_tenant_xyz_pass }}"
    roles: ["core-admin-srhecampus"]
```

---

## 📚 Weitere Informationen

- **PLAYBOOK_USAGE.md** - Vollständige Nutzungsanleitung
- **USER_MANAGEMENT.md** - User-Management Details
- **host_vars_example_v38.yml** - Vollständige Config-Vorlage

---

## 🆘 Support

Bei Problemen:

1. Logs prüfen: `docker logs hc-srhecampus-solr`
2. Verbose Output: `ansible-playbook ... -vvv`
3. Tests ausführen: `--tags=install-solr-test`
4. Container neu starten: `docker restart hc-srhecampus-solr`

**Kritische Bugs:** Siehe `BUG_SEARCH_ANALYSIS_v1.3.2.md`

---

**Viel Erfolg bei der Migration! 🚀**
