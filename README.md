# Solr Installation Role v1.2.1

**Version:** 1.2.1  
**Maintainer:** Bernd Schreistetter  
**Kompatibilität:** Ansible 2.12.0 - 2.15.x  
**Solr-Version:** 9.9.0  
**Moodle-Kompatibilität:** 4.1, 4.2, 4.3, 4.4, 5.0.x

---

## Übersicht

Diese Ansible-Role stellt eine Installation von Apache Solr 9.9.0 in Docker-Containern bereit. Version 1.2.1 erweitert v1.0 um **vollständige Moodle-Integration** mit spezifischem Schema und Test-Dokumenten.

### Neue Features in v1.2.x

- **Moodle Schema Support**: Vorgefertigtes Schema für Moodle Global Search (4.1 - 5.0.x)
- **Moodle Test Documents**: 5 Test-Dokument-Typen (Forum, Wiki, Course, Assignment, Page)
- **Schema Validation**: Automatische Validierung der Moodle-Felder
- **Flexible Aktivierung**: Moodle-Features optional ein/ausschaltbar

### Features aus v1.1 (weiterhin enthalten)

- **Pre-Deployment Authentication**: security.json wird VOR dem ersten Container-Start erstellt (Basic Auth Plugin / Role Based ? )
- **Init-Container Pattern**: Für eine hoffetlich Garantiert korrekte Deployment-Reihenfolge (Auth Probleme [Tested Datum])
- **Rundeck-Integration**: Vollständige Monitoring- und Automation-Integration (Untested und für Kkeck)
- **Modulare Task-Struktur**: 16 Task-Dateien a max. 250 Zeilen ← **AKTUALISIERT: +2 in v1.2.x**
- **Style Guide konform**: Befolgt weitestgehend eLeDia Naming Conventions (Guidlines bla)
- **Idempotent**: Kann beliebig oft ausgeführt werden ohne Schaden (Hoffentlich)

---

## Architektur

### Task-Reihenfolge v1.2.x

```
1.  preflight_checks.yml      → System-Validierung
2.  system_preparation.yml    → Verzeichnisse, Limits
3.  docker_installation.yml   → Docker + Docker Compose
4.  auth_prehash.yml          → Passwörter mit bcrypt hashen
5.  auth_securityjson.yml     → security.json erstellen
6.  compose_generation.yml    → docker-compose.yml generieren
7.  container_deployment.yml  → Init-Container + Solr starten
8.  auth_validation.yml       → Auth-Tests durchführen
9.  auth_persistence.yml      → Credentials speichern
10. core_creation.yml         → Solr Core erstellen
11. moodle_schema_preparation.yml  → Moodle Schema generieren ← NEU v1.2
12. proxy_configuration.yml   → Apache/Nginx Proxy
13. integration_tests.yml     → Vollständige Tests
14. moodle_test_documents.yml → Moodle Test-Docs indexieren ← NEU v1.2
15. finalization.yml          → Backup-Scripts, Logrotate
16. rundeck_integration.yml   → Rundeck Jobs registrieren
```

**WICHTIG:** Auth MUSS vor Deployment erfolgen!

### Verzeichnisstruktur v1.2

```
/opt/solr/
├── config/                   # Pre-Deployment Configs
│   ├── security.json         # Erstellt BEVOR Container startet
│   └── moodle_schema.xml     # NEU: Moodle-Schema (optional)
├── docker-compose.yml        # Compose-Konfiguration
└── .env                      # Environment Variables

/var/solr/
├── data/                     # Named Volume (Docker-managed)
│   └── security.json         # Vom Init-Container kopiert
└── backup/                   # Backup-Verzeichnis

/usr/local/bin/
├── solr_health_check         # Rundeck Health Check
└── solr_rundeck_webhook      # Webhook Receiver
```

---

## Installation

### Voraussetzungen

```bash
# System-Pakete
apt-get install -y \
  docker.io \
  docker-compose-plugin \
  apache2-utils \
  jq \
  curl

# Docker starten
systemctl enable --now docker
```

### 1. Role in Playbook einbinden

```yaml
---
# install_solr.yml
- name: Install Solr with authentication and Moodle support
  hosts: solr_servers
  become: true
  roles:
    - install-solr
```

### 2. Inventory konfigurieren (Ansibile Guideline Komform)

```ini
# inventory/hosts
[solr_servers]
server01 ansible_host=0.0.0.0

[solr_servers:vars]
customer_name=kunde01
moodle_app_domain=kunde01.example.com
```

### 3. Host-Variablen setzen

```yaml
# host_vars/server01.yml
customer_name: kunde01
moodle_app_domain: kunde01.example.com
solr_version: "9.9.0"
solr_port: 8983
solr_heap_size: "1g"

# NEU in v1.2: Moodle-Optionen
solr_use_moodle_schema: true      # Moodle-Schema verwenden (default: true)
solr_moodle_test_docs: true       # Test-Dokumente indexieren (default: false)

# Optional: Bestehende Credentials (werden sonst generiert)
# solr_admin_password: "secure_password_123"
# solr_support_password: "support_password_456"
# solr_customer_password: "customer_password_789"
```

### 4. Playbook ausführen

```bash
# Vollständige Installation
ansible-playbook install_solr.yml -i inventory/hosts

# Mit Tags (nur bestimmte Phasen)
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-auth

# Nur Moodle-Features (bei bestehender Installation)
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle

# Check-Mode (Dry-Run)
ansible-playbook install_solr.yml -i inventory/hosts --check
```

---

## Moodle-Integration ← **NEU in v1.2**

### Automatische Schema-Generierung

Wenn `solr_use_moodle_schema: true` (Standard), wird automatisch ein Moodle-spezifisches Schema erstellt:

```yaml
# Moodle-Schema-Felder (Auswahl)
- id               # Unique identifier
- title            # Document title
- content          # Main searchable content
- contextid        # Moodle context ID
- courseid         # Course association
- owneruserid      # Document owner
- modified         # Timestamp
- type             # Document type (forum_post, wiki_page, etc.)
- areaid           # Search area identifier
- itemid           # Moodle item ID
- modname          # Module name (forum, wiki, assign, etc.)
- username         # User display name
- categoryid       # Course category
```

### Moodle-Versionen Unterstützt

- Moodle 4.1.x ✅
- Moodle 4.2.x ✅
- Moodle 4.3.x ✅
- Moodle 4.4.x ✅
- Moodle 5.0.x ✅

### Test-Dokumente

Bei Aktivierung von `solr_moodle_test_docs: true` werden folgende Test-Dokumente indexiert:

1. **Forum Post** - "Einführung in die Mathematik"
2. **Wiki Page** - "Projektmanagement Methoden"
3. **Course Module** - "Einführung in Python Programmierung"
4. **Assignment** - "Hausaufgabe: Datenbankdesign"
5. **Page Resource** - "Lernmaterialien: HTML und CSS"

**Verwendung:**
```bash
# Test-Dokumente indexieren
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle-test

# Suche testen
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/select?q=title:Mathematik"
```

### Moodle Config.php Konfiguration

Nach erfolgreicher Installation Solr in Moodle konfigurieren:

```php
// In config.php oder via Admin-Interface
$CFG->searchengine = 'solr';
$CFG->searchhosts = ['http://localhost:8983/solr'];
$CFG->searchindexname = 'kunde01_core';
$CFG->searchuser = 'customer';
$CFG->searchpassword = 'PASSWORD_FROM_CREDENTIALS_FILE';
```

---

## Authentifizierung

### Bcrypt-Hashing (OutOfDate) - Wer Lesen kann ist klar im Vorteil.
### SHA-256 (UpdaTODate)
Version 1.1+ verwendet ` SHA-256` (solrbasicath) für  SHA-256 Hasing:

#
```yaml
# tasks/auth_prehash.yml
- name: Generate SHA-256 hash for admin
  #code
  register: admin_hash
```

**Vorteile:**
- Keine Python-Dependencies
- Native SHA-256 intern von Solr
- Deterministische Hashes für Idempotenz

### security.json Struktur

```json
{
  "authentication": {
    "blockUnknown": true,
    "class": "solr.BasicAuthPlugin",
    "credentials": {
      "admin": "SHA-256...",
      "support": "SHA-256...",
      "customer": "SHA-256..."
    }
  },
  "authorization": {
    "class": "solr.RuleBasedAuthorizationPlugin",
    "permissions": [...],
    "user-role": {...}
  }
}
```

### Credential-Speicherung

Nach erfolgreicher Installation werden Credentials gespeichert in:

1. **host_vars/{{ inventory_hostname }}** (für Ansible-Wiederverwendung)
2. **/var/solr/.credentials_backup_{{ epoch }}** (als Backup)
3. **/var/solr/.rundeck_credentials.json** (für Rundeck-Integration)

**Empfehlung:** Verschlüsseln mit Ansible Vault: (Hinweis) hab noch keine Erfahrung damit

```bash
ansible-vault encrypt host_vars/server01.yml
```

---

## Init-Container Pattern

### Problem (v1.0) oder irgendwas (Schrott)

```
Container startet → API-Call für User → Solr generiert Hash → 
Container-Restart → security.json weg → 401-Fehler
```

### Lösung (v1.1+)

```
Pre-Hash Passwörter → Erstelle security.json → mit SHA-256 Hashung
Init-Container kopiert security.json → Solr startet mit Auth → 
Container-Restart → security.json bleibt (Named Volume) → Funktioniert! (Needs to be Tested)

```

### docker-compose.yml

```yaml
services:
  solr-init:
    image: alpine:3.18
    command: sh -c "
      cp /config/security.json /var/solr/data/security.json;
      chown 8983:8983 /var/solr/data/security.json;
      "
    volumes:
      - solr_data:/var/solr
      - /opt/solr/config:/config:ro

  solr:
    image: solr:9.9.0
    depends_on:
      solr-init:
        condition: service_completed_successfully
    volumes:
      - solr_data:/var/solr

volumes:
  solr_data:
    name: solr_data_kunde01
```

---

## Rundeck-Integration

### Aktivierung

```yaml
# host_vars/kundexyz.yml
rundeck_integration_enabled: true
rundeck_api_url: "https://rundeck.example.com"
rundeck_api_token: "your_api_token_here"
rundeck_project_name: "solr_monitoring"
rundeck_webhook_enabled: true
rundeck_webhook_secret: "secure_webhook_secret"
```

### Registrierte Jobs

1. **Solr Health Check**
   - Läuft alle 5 Minuten
   - JSON-Output
   - Endpoint: `/usr/local/bin/solr_health_check`

2. **Solr Backup**
   - Täglich um 02:00 Uhr
   - 7 Tage Retention
   - Email-Benachrichtigung

3. **Solr Restart**
   - Manueller Trigger
   - Mit Health-Check nach Restart

### Webhook-Nutzung

```bash
# Health Check
/usr/local/bin/solr_rundeck_webhook "webhook_secret" "health"

# Restart
/usr/local/bin/solr_rundeck_webhook "webhook_secret" "restart"

# Backup
/usr/local/bin/solr_rundeck_webhook "webhook_secret" "backup"
```

---

## Testing

### Manuelle Tests

```bash
# 1. Container-Status
docker ps | grep solr

# 2. Logs prüfen
docker logs solr_kunde01

# 3. Health-Check
curl http://localhost:8983/solr/admin/ping

# 4. Auth testen (sollte 401 zurückgeben)
curl http://localhost:8983/solr/admin/info/system

# 5. Auth mit Credentials
curl -u admin:PASSWORD http://localhost:8983/solr/admin/info/system

# 6. Container-Restart-Test
docker compose -f /opt/solr/docker-compose.yml restart
sleep 15
curl -u admin:PASSWORD http://localhost:8983/solr/admin/info/system

# 7. NEU: Moodle-Schema testen
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/schema/fields" | \
  jq '.fields[] | select(.name | contains("course"))'

# 8. NEU: Moodle Test-Docs suchen
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/select?q=type:forum_post"
```

### Automated Tests

```bash
# Nur Tests ausführen
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-test

# NEU: Nur Moodle-Tests
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle-test
```

---

## Troubleshooting

### Auth funktioniert nicht (Sollte behoben sein benötigt Testing! )

```bash
# 1. security.json im Container prüfen
docker exec solr_kunde01 cat /var/solr/data/security.json

# 2. Permissions prüfen
docker exec solr_kunde01 ls -la /var/solr/data/security.json

# 3. Init-Container-Logs
docker logs solr_kunde01_init

# 4. Solr-Logs
docker logs solr_kunde01 | grep -i security
```

### Init-Container schlägt fehl

```bash
# 1. Prüfen ob security.json existiert
ls -la /opt/solr/config/security.json

# 2. Manuelle Ausführung des Init-Befehls
docker run --rm \
  -v solr_data_kunde01:/var/solr \
  -v /opt/solr/config:/config:ro \
  alpine:3.18 \
  sh -c "cp /config/security.json /var/solr/data/; ls -la /var/solr/data/"
```

### Moodle-Schema nicht gefunden ← **Seit Moodle Optimierung**

```bash
# 1. Schema-Datei prüfen
ls -la /opt/solr/config/moodle_schema.xml

# 2. Schema neu generieren
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle

# 3. Core-Schema anzeigen
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/schema/fields"
```

### Moodle Test-Dokumente fehlen ← **Seit Moodle Optimierung**

```bash
# 1. Anzahl Dokumente prüfen
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/select?q=*:*&rows=0"

# 2. Test-Docs neu indexieren
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle-test

# 3. Nach Test-Docs suchen
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/select?q=type:forum_post"
```

### Credentials vergessen

```bash
# 1. In host_vars nachschauen
cat host_vars/server01.yml | grep password

# 2. Backup-Datei prüfen
sudo cat /var/solr/.credentials_backup_*

# 3. Rundeck-Credentials
sudo cat /var/solr/.rundeck_credentials.json
```

### Port bereits belegt

```bash
# 1. Prozess finden
lsof -i :8983

# 2. Anderen Port verwenden
# In host_vars/server01.yml:
solr_port: 18983

# 3. Playbook neu ausführen
ansible-playbook install_solr.yml -i inventory/hosts
```

---

## Wartung

### Backup erstellen

```bash
# Manuell
docker exec solr_kunde01 solr backup \
  -c kunde01_core \
  -d /var/solr/backup \
  -name manual_backup_$(date +%Y%m%d)

# Via Rundeck (wenn aktiviert)
/usr/local/bin/solr_rundeck_webhook "secret" "backup"
```

### Backup wiederherstellen

```bash
docker exec solr_kunde01 solr restore \
  -c kunde01_core \
  -d /var/solr/backup \
  -name manual_backup_20251024
```

### Container-Update

```bash
cd /opt/solr
docker compose pull
docker compose up -d
```

### Logs rotieren

Automatisch konfiguriert via `/etc/logrotate.d/solr`:
- Täglich rotieren
- 7 Tage behalten
- Komprimiert speichern
- Mit More Infos :) Markus wird es Lieben

---

## Migration

### Von v1.0 zu v1.1

1. **Backup erstellen**
```bash
docker exec solr_kunde01 solr backup -c kunde01_core -d /var/solr/backup -name pre_v11_backup
```

2. **Alte Installation stoppen**
```bash
docker stop solr_kunde01
docker rm solr_kunde01
```

3. **v1.1 deployen**
```bash
ansible-playbook install_solr.yml -i inventory/hosts
```

### Von v1.1 zu v1.2 ← **NEU**

**WICHTIG-Breaking Changes:** Keine Breaking Changes gefunden.

```bash
# Einfach v1.2 deployen
ansible-playbook install_solr.yml -i inventory/hosts

# Optional: Moodle-Features aktivieren
# In host_vars/server01.yml:
solr_use_moodle_schema: true
solr_moodle_test_docs: true

# Schema nachrüsten
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle
```

**Breaking Changes:** KEINE - v1.2 ist vollständig rückwärtskompatibel. Bestehende Credentials und Cores bleiben erhalten.

---

## Sicherheit

### Empfohlene Maßnahmen

1. **Vault-Verschlüsselung**
```bash
ansible-vault encrypt host_vars/server01.yml
```

2. **Firewall-Regeln**
```bash
ufw allow from 192.168.1.0/24 to any port 8983
```

3. **SSL/TLS aktivieren**
```yaml
solr_ssl_enabled: true
solr_proxy_enabled: true
```

4. **Regelmäßige Updates**
```bash
ansible-playbook install_solr.yml -i inventory/hosts -e "solr_force_pull=true"
```

5. **Credential-Rotation**
```yaml
# In host_vars setzen
solr_force_reconfigure_auth: true
solr_admin_password: "new_secure_password"
```

---

## Style Guide Konformität

Diese Role befolgt den eLeDia Ansible Style Guide:

- ✅ Kebab-case für Role-Namen (`install-solr`)
- ✅ Snake_case für Task-Dateien (`auth_prehash.yml`)
- ✅ Dictionary-Struktur für Task-Parameter
- ✅ Keine Listen-Notation (`when:` mit Unterpunkten)
- ✅ Max. 1 Leerzeile zwischen Tasks
- ✅ Keine auskommentierten Tasks
- ✅ Ansible-Managed Header in Templates
- ✅ 2 Spaces Einrückung

---

## Bekannte Limitierungen
### v1.2.1 (26.10)
1. Moodle-Schema ist read-only nach Core-Erstellung (Solr-Limitation)
2. Test-Dokumente sind Demo-Daten (keine echten Moodle-Daten)
3. Schema-Änderungen erfordern Core-Neuanlage
### v1.2
1. Moodle-Schema ist read-only nach Core-Erstellung (Solr-Limitation)
2. Test-Dokumente sind Demo-Daten (keine echten Moodle-Daten)
3. Schema-Änderungen erfordern Core-Neuanlage

### v1.1
1. Rundeck-Integration erfordert manuelle API-Token-Konfiguration
2. Webhook-Receiver benötigt nginx/Apache für HTTPS-Zugriff
3. Email-Benachrichtigungen erfordern konfigurierte Mail-Relay

---

## Lizenz

Das was Markus und Sehart sagen ;)

---

## Support

**Maintainer:** Bernd Schreistetter  
**Email:** bernd.schreistetter@eledia.de oder info ? 
**Dokumentation:** Kein Recht in Redmine somit hier in der Rolle mitverpackt
**Version:** 1.2.0  
**Datum:** 25.10.2025