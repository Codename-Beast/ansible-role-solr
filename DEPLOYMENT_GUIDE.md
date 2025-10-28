# Solr v1.1 Deployment Guide

**Version:** 1.1.0  
**Maintainer:** Bernd Schreistetter

---

## Schnellstart (5 Minuten)

### 1. Role installieren

```bash
cd /ansible/roles
tar -xzf install-solr-v1.1.tar.gz
mv install-solr-v1.1 install-solr
```

### 2. Playbook erstellen

```bash
cat > /ansible/playbooks/install_solr.yml <<'EOF'
---
- name: Install Solr with pre-deployment auth
  hosts: solr_servers
  become: true
  roles:
    - install-solr
EOF
```

### 3. Deployment starten

```bash
ansible-playbook \
  ansible/playbooks/install_solr.yml \
  -i ansible/inventory/hosts \
  --diff
```

### 4. Verifikation

```bash
# Auf dem Ziel-Server
curl http://localhost:8983/solr/admin/ping
# Sollte 401 zurückgeben (Auth aktiv)

# Credentials aus host_vars holen
cat /ansible/inventory/host_vars/kunde_hostvar | grep solr_password

# Mit Auth testen
curl -u admin:PASSWORD http://localhost:8983/solr/admin/info/system
# Sollte 200 zurückgeben
```

---

## Architektur-Überblick

```
┌─────────────────────────────────────────────────┐
│  1. PREFLIGHT CHECKS                            │
│     - OS-Validierung (Debian 10+)              │
│     - Disk/Memory-Check                         │
│     - Docker/htpasswd-Verfügbarkeit            │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  2. SYSTEM PREPARATION                          │
│     - Verzeichnisse erstellen                   │
│     - System-Limits setzen                      │
│     - Docker-Network erstellen                  │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  3. DOCKER INSTALLATION                         │
│     - Docker CE installieren                    │
│     - Docker Compose v2 installieren            │
│     - apache2-utils (htpasswd)                  │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  4. AUTH PRE-HASH (DEV)                    │
│     - Passwörter generieren/laden               │
│     - htpasswd bcrypt hashing (10 rounds)       │
│     - Hash-Verifikation                         │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  5. AUTH SECURITY JSON                          │
│     - security.json aus Hashes erstellen        │
│     - Nach /opt/solr/config/ schreiben         │
│     - JSON-Syntax validieren                    │
│     - Ownership 8983:8983 setzen               │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  6. COMPOSE GENERATION                          │
│     - docker-compose.yml generieren             │
│     - Init-Container konfigurieren              │
│     - Named Volume definieren                   │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  7. CONTAINER DEPLOYMENT                        │
│     ┌─────────────────────────────────────┐    │
│     │ Init-Container (Alpine)              │    │
│     │ - Kopiert security.json              │    │
│     │ - Setzt Permissions (8983:8983)      │    │
│     │ - Beendet sich (exit 0)             │    │
│     └─────────────┬───────────────────────┘    │
│                   ▼                              │
│     ┌─────────────────────────────────────┐    │
│     │ Solr Container                       │    │
│     │ - Startet NUR wenn Init OK           │    │
│     │ - Liest security.json aus Volume     │    │
│     │ - Auth ist vom Start an aktiv!      │    │
│     └─────────────────────────────────────┘    │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  8. AUTH VALIDATION                             │
│     - Unauthenticated = 401 ✓                  │
│     - Admin Login = 200 ✓  x                    │
│     - Support Login = 200 ✓ x                   │
│     - Customer Login = 200 ✓ x                │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  9. AUTH PERSISTENCE                            │
│     - Credentials in host_vars speichern        │
│     - Backup nach /var/solr erstellen          │
│     - Rundeck JSON exportieren                  │
└──────────────────┬──────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────┐
│  10-14. CORE, PROXY, TESTS, FINALIZE, RUNDECK  │
└─────────────────────────────────────────────────┘
```

---

## Kritische Unterschiede zu v1.0

### v1.0 (PROBLEM)
```yaml
1. Container starten
2. Warten auf Solr
3. API-Call: /admin/authentication → User erstellen
4. Solr generiert Hash mit NEUEM Salt
5. Container-Restart
6. security.json WEG (kein Volume wie dumm :) )
7. → Zurück zu Schritt 3 → Immer neuer Hash → 401
```

### v1.1 (Mögliche LÖSUNG)
```yaml
1. htpasswd: Passwort hashen (OFFLINE)
2. security.json mit Hash erstellen
3. security.json nach /opt/solr/config/ schreiben
4. Init-Container startet
5. Init-Container kopiert security.json → /var/solr/data/
6. Init-Container beendet sich
7. Solr Container startet (depends_on: init)
8. Solr liest existierende security.json
9. Container-Restart
10. security.json bleibt (Named Volume)
11. → Auth funktioniert! ✓
```

---

## Verzeichnis-Layout

```
Server File System
├── /opt/solr/                    [solr_compose_dir]
│   ├── config/
│   │   └── security.json         PRE-DEPLOYMENT (8983:8983)
│   ├── docker-compose.yml
│   └── .env
│
├── /var/solr/                    [Named Docker Volume]
│   ├── data/
│   │   └── security.json         Von Init-Container kopiert
│   └── backup/
│       └── backup_YYYYMMDD_HHMMSS/
│
├── /usr/local/bin/
│   ├── solr_health_check         Rundeck Health-Check
│   └── solr_rundeck_webhook      Webhook Receiver
│
└── /etc/ansible/
    └── inventory/
        └── host_vars/
            └── server01          CREDENTIALS (Vault-ready)
```

---

## Variable Reference

### Pflicht-Variablen

```yaml
customer_name: "kunde01"
moodle_app_domain: "kunde01.example.com"
```

### Wichtige Default-Überschreibungen

```yaml
# Memory
solr_heap_size: "1g"              # Standard: 512m
solr_memory_limit: "2g"           # Standard: 1g

# Auth
solr_force_reconfigure_auth: true  # Credentials rotieren
solr_bcrypt_rounds: 12            # Mehr Sicherheit (Standard: 10)

# Backup
solr_backup_enabled: true
solr_backup_retention: 14         # Standard: 7 Tage

# Rundeck
rundeck_integration_enabled: true
rundeck_api_url: "https://rundeck.eledia.de"
rundeck_api_token: "YOUR_TOKEN"
rundeck_project_name: "solr_monitoring"
```

### Debug-Variablen

```yaml
solr_force_recreate: true         # Container-Neustart erzwingen
solr_force_pull: true             # Image neu pullen
```

---

## Credential Management

### Generierung

```yaml
# Option 1: Auto-Generate (Standard)
# Keine Variablen setzen → werden generiert

# Option 2: Explizit setzen
solr_admin_password: "your_secure_password_here"
solr_support_password: "support_pass"
solr_customer_password: "customer_pass"
```

### Speicherorte

```bash
# 1. Ansible host_vars (Primär) #Anpassen!
/ansible/inventory/host_vars/server01

# 2. Server Backup
/var/solr/.credentials_backup_EPOCH

# 3. Rundeck Export (wenn aktiviert)
/var/solr/.rundeck_credentials.json
```

### Vault-Verschlüsselung

```bash
# Verschlüsseln
ansible-vault encrypt ansible/inventory/host_vars/server01

# Entschlüsseln
ansible-vault decrypt ansible/inventory/host_vars/server01

# View ohne Decrypt
ansible-vault view /ansible/inventory/host_vars/server01

# Playbook mit Vault
ansible-playbook install_solr.yml --ask-vault-pass
```

---

## Rundeck Integration

### Setup

```yaml
# In host_vars/server01
rundeck_integration_enabled: true
rundeck_api_url: "https://rundeck.eledia.de"
rundeck_api_token: "TOKEN_FROM_RUNDECK_WEBUI"
rundeck_project_name: "infrastructure"
rundeck_webhook_enabled: true
rundeck_webhook_secret: "random_secure_string"
```

### Jobs

Nach Deployment werden folgende Jobs registriert:

1. **solr-health-check-kunde01**
   - Schedule: */5 * * * * (alle 5 Minuten)
   - Output: JSON
   - Timeout: 30s

2. **solr-backup-kunde01**
   - Schedule: 0 2 * * * (täglich 02:00)
   - Retention: 7 Tage
   - Email bei Fehler

3. **solr-restart-kunde01**
   - Schedule: Manuell
   - Mit Health-Check nach Restart

### Webhook Usage

```bash
# Lokal (auf dem Server)
/usr/local/bin/solr_rundeck_webhook "webhook_secret" "health"

# Remote (über HTTP - benötigt nginx/Apache Setup)
curl -X POST https://eledia.de/webhook/solr \
  -H "X-Webhook-Secret: webhook_secret" \
  -d '{"action":"restart"}'
```

---

## Troubleshooting Playbook

```yaml
---
# troubleshoot_solr.yml
- name: Solr Troubleshooting
  hosts: solr_servers
  become: true
  tasks:
    - name: Check container status
      command: docker ps -a | grep solr
      register: container_status
      changed_when: false
    
    - name: Display container status
      debug:
        var: container_status.stdout_lines
    
    - name: Check security.json existence
      stat:
        path: /opt/solr/config/security.json
      register: config_security
    
    - name: Check security.json in volume
      command: docker exec solr_kunde01 test -f /var/solr/data/security.json
      register: volume_security
      failed_when: false
    
    - name: Display security.json status
      debug:
        msg:
          - "Config security.json exists: {{ config_security.stat.exists }}"
          - "Volume security.json exists: {{ volume_security.rc == 0 }}"
    
    - name: Check init-container logs
      command: docker logs solr_kunde01_init
      register: init_logs
      failed_when: false
    
    - name: Display init-container logs
      debug:
        var: init_logs.stdout_lines
    
    - name: Check Solr logs
      command: docker logs solr_kunde01 --tail 50
      register: solr_logs
      failed_when: false
    
    - name: Display Solr logs
      debug:
        var: solr_logs.stdout_lines
```

```bash
# Ausführen
ansible-playbook troubleshoot_solr.yml -i inventory/hosts
```

---

## Common Issues

### 1. "Container starts but Auth fails (401)"

**Ursache:** security.json nicht im Volume bzw überlebt Restart nicht.

**Lösung:**
```bash
# Check
docker exec solr_kunde01 ls -la /var/solr/data/security.json

# Fix
cd /opt/solr
docker compose down
ansible-playbook install_solr.yml -i inventory -e "solr_force_reconfigure_auth=true"
```

### 2. "Init-Container fails"

**Ursache:** security.json nicht in /opt/solr/config

**Lösung:**
```bash
# Check
ls -la /opt/solr/config/security.json

# Fix
ansible-playbook install_solr.yml -i inventory --tags install-solr-auth
```

### 3. "htpasswd not found"

**Ursache:** apache2-utils nicht installiert

**Lösung:**
```bash
apt-get update
apt-get install -y apache2-utils

# Oder Playbook neu ausführen
ansible-playbook install_solr.yml -i inventory --tags install-solr-preparation
```

### 4. "Port 8983 already in use"

**Lösung 1:** Anderen Port verwenden
```yaml
# In host_vars
solr_port: 18983
```

**Lösung 2:** Konflikt beseitigen
```bash
lsof -i :8983
kill -9 PID
```

---

## Performance Tuning

### Memory

```yaml
# Für kleine Instanzen (<10k Dokumente)
solr_heap_size: "512m"
solr_memory_limit: "1g"

# Für mittlere Instanzen (10k-100k Dokumente)
solr_heap_size: "1g"
solr_memory_limit: "2g"

# Für große Instanzen (>100k Dokumente)
solr_heap_size: "2g"
solr_memory_limit: "4g"
```

### CPU

```yaml
# CPU-Limits setzen
solr_cpu_quota: 200000   # 2 CPUs
solr_cpu_period: 100000
```

---

## Sicherheit Best Practices

1. **Vault verwenden**
```bash
ansible-vault encrypt host_vars/server01
```

2. **Firewall konfigurieren**
```bash
ufw allow from ip:/24 to any port 8983
ufw enable
```

3. **SSL/TLS aktivieren**
```yaml
solr_ssl_enabled: true
solr_proxy_enabled: true
```

4. **Regelmäßige Updates**
```bash
# Monthly
ansible-playbook install_solr.yml -i inventory -e "solr_force_pull=true"
```

5. **Backup-Strategie**
```yaml
solr_backup_enabled: true
solr_backup_retention: 14  # 2 Wochen
```

---

## Support

**Maintainer:** Bernd Schreistetter  
**Email:** bernd.schreistetter@eledia.de  
**Version:** 1.2.1  
**Status:** Test Ready

---

## Links

- [README.md](README.md) - Vollständige Dokumentation
- [CHANGELOG.md](CHANGELOG.md) - Änderungshistorie so ungefähr
- Redmine-Artikel: Hab keine Rechte also in der Rolle <3
- Solr Dokumentation: https://solr.apache.org/guide/9_9/

---

**Deployment Time:** 3 - 5 Minuten  
**Idempotent:** Ja  
**Rundeck-ready:** Ja aber nicht getestet warte auf Kkeck
