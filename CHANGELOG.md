# Changelog - Solr Installation Role

## Version 1.2.0 - 25.10.2025

**Maintainer:** Bernd Schreistetter  
**Typ:** Feature Release - Moodle Integration  
**Priorität:** Mittel - Erweitert v1.1 um Moodle-spezifische Features

---

### Übersicht

Version 1.2.1 erweitert die v1.1 Basis um **vollständige Moodle-Integration**. Moodle-spezifisches Solr-Schema für Versionen 4.1 bis 5.0.x, automatisierte Test-Dokumente und Schema-Validierung sind jetzt verfügbar.

---

### Neue Features

#### 1. Moodle Schema Support
- **NEU:** Moodle-spezifisches Solr Schema Template (moodle_schema.xml.j2)
- **NEU:** Kompatibilität für Moodle 4.1, 4.2, 4.3, 4.4, 5.0.x
- **NEU:** Automatische Schema-Generierung mit allen Moodle-Standardfeldern
- **VORTEIL:** Plug-and-play Integration für Moodle Global Search

#### 2. Moodle Test Documents
- **NEU:** 5 vorgefertigte Test-Dokument-Typen
- **NEU:** Forum Posts, Wiki Pages, Course Modules, Assignments, Page Resources
- **NEU:** Automatisierte Such-Tests (by title, content, courseid, type, facets)
- **NEU:** Rundeck-kompatible Test-Reports
- **VORTEIL:** Validierung der Moodle-Integration ohne echte Moodle-Installation

#### 3. Schema Preparation Task
- **NEU:** tasks/moodle_schema_preparation.yml
- **NEU:** Schema-Validierung
- **NEU:** Moodle-Versions-Check
- **VORTEIL:** Garantiert korrektes Schema vor Core-Erstellung

#### 4. Erweiterte Variablen
- **NEU:** solr_use_moodle_schema (default: true)
- **NEU:** solr_moodle_test_docs (default: false)
- **NEU:** solr_moodle_versions Liste
- **VORTEIL:** Flexible Aktivierung/Deaktivierung von Moodle-Features

---

### Geänderte Dateien

#### defaults/main.yml
**Status:** ERWEITERT (v1.1 → v1.2 → v1.2.1 )  
**Neue Variablen:**
```yaml
solr_use_moodle_schema: true
solr_moodle_test_docs: false
solr_moodle_versions: ["4.1", "4.2", "4.3", "4.4", "5.0.x"]
```

#### tasks/main.yml
**Status:** ERWEITERT  
**Neue Task-Includes:**
- moodle_schema_preparation.yml (nach core_creation, vor proxy_configuration)
- moodle_test_documents.yml (optional, nach integration_tests)

---

### Neue Task-Dateien

#### 1. moodle_schema_preparation.yml
**Funktion:** Moodle-Schema generieren und validieren  
**Zeilen:** ~50  
**Highlights:**
- Template-basierte Schema-Generierung
- Schema-Existenz-Prüfung
- Moodle-Versions-Kompatibilitäts-Info
- Rundeck-JSON-Output

#### 2. moodle_test_documents.yml
**Funktion:** Test-Dokumente für Moodle-Integration  
**Zeilen:** ~310  
**Highlights:**
- 5 verschiedene Moodle-Dokumenttypen
- Automatische Indexierung
- 4 Such-Tests (title, content, courseid, type)
- Facet-Search-Test
- Commit-Verifikation
- Umfangreiche Rundeck-Reports

---

### Neue Template-Dateien

#### 1. moodle_schema.xml.j2
**NEU:** Moodle-spezifisches Solr Schema  
**Zeilen:** ~150 (geschätzt)  
**Moodle-Felder:**
- id (unique identifier)
- title (searchable text)
- content (main searchable content)
- contextid (Moodle context)
- courseid (course association)
- owneruserid (document owner)
- modified (timestamp)
- type (document type: forum_post, wiki_page, etc.)
- areaid (search area identifier)
- itemid (Moodle item ID)
- modname (module name: forum, wiki, assign, etc.)
- username (user display name)
- categoryid (course category)
- intro/description (additional text fields)

**Moodle-Kompatibilität:** 4.1, 4.2, 4.3, 4.4, 5.0.x

---

### Task-Reihenfolge v1.2

```
1.  preflight_checks.yml
2.  system_preparation.yml
3.  docker_installation.yml
4.  auth_prehash.yml
5.  auth_securityjson.yml
6.  compose_generation.yml
7.  container_deployment.yml
8.  auth_validation.yml
9.  auth_persistence.yml
10. core_creation.yml
11. moodle_schema_preparation.yml    ← NEU in v1.2
12. proxy_configuration.yml
13. integration_tests.yml
14. moodle_test_documents.yml        ← NEU in v1.2 (optional)
15. finalization.yml
16. rundeck_integration.yml
```

---

### Migration von v1.1 zu v1.2 und v1.2.1

**WICHTIG:** v1.2 ist rückwärtskompatibel!

#### Automatisches Upgrade
```bash
# Einfach v1.2.1 deployen - keine Breaking Changes
ansible-playbook install_solr.yml -i inventory/hosts
```

#### Optionale Moodle-Features aktivieren
```yaml
# In host_vars/server01.yml
solr_use_moodle_schema: true          # Schema verwenden (Standard: true)
solr_moodle_test_docs: true           # Test-Docs indexieren (Standard: false)
```

#### Moodle-Schema nachrüsten (für bestehende v1.1 Installationen)
```bash
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle
```

---

### Testing v1.2

#### Manuelles Moodle-Schema-Test
```bash
# Schema-Datei prüfen
cat /opt/solr/config/moodle_schema.xml

# Im Core prüfen (nach Deployment)
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/schema/fields" | jq '.fields[] | select(.name | startswith("moodle"))'
```

#### Moodle Test-Documents ausführen
```bash
# Nur Moodle-Tests
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-moodle-test

# Prüfen ob Dokumente indexiert
curl -u customer:PASSWORD "http://localhost:8983/solr/kunde01_core/select?q=type:forum_post" | jq '.response.numFound'
```

---

### Bekannte Limitierungen v1.2

1. Moodle-Schema ist read-only nach Core-Erstellung (Solr-Limitation)
2. Test-Dokumente sind Demo-Daten (keine echten Moodle-Daten)
3. Schema-Änderungen erfordern Core-Neuanlage
4. Keine automatische Schema-Migration von basic_configs → moodle_schema

---

### Nächste Schritte (v1.3 geplant)

- [Planned] Multi-Core-Support
- [Planned] Exclude it from Moodle Instance (Singel Server Multiple users/cores)
- [Planned] Prometheus-Metrics-Export
- [Planned] Grafana-Dashboard-Template
- [Planned] Automated Certificate Rotation
- [InProgress] More Rundeck-Integration options
- [InProgress] Standalone Server mit keiner Zwingenden Moodle Installation. Gebunden (1.1)
- [NEW] Moodle Config.php Auto-Configuration (schreibt Solr-Settings direkt in Moodle)

---

## Version 1.1.0

**Maintainer:** Bernd Schreistetter  
**Typ:** Major Feature Release + Bugfix  
**Priorität:** Hoch - Löst kritisches BasicAuth-Problem (Funfact hat es nicht)

---

### Übersicht

Version 1.1.0 implementiert das **Init-Container-Pattern mit Pre-Deployment-Authentication** und eliminiert alle Python-Abhängigkeiten. Diese Version löst das "Rehashing-Problem" von Solr 9.9.0 systematisch.

---

### Neue Features

#### 1. Pre-Deployment Authentication
- **NEU:** Passwörter werden VOR Container-Start gehasht
- **NEU:** security.json wird in `/opt/solr/config/` erstellt BEVOR Container startet
- **NEU:** Init-Container kopiert security.json mit korrekten Permissions
- **VORTEIL:** Keine API-basierten Passwort-Operationen mehr (eliminiert Race Conditions)

#### 2. Python-freie Implementation
- **ENTFERNT:** Alle Python-Scripts und Dependencies
- **ENTFERNT:** htpasswd (apache2-utils) für bcrypt-Hashing (Solr regelt :) )
- **NEU:** Native Shell-Implementierung für alle Auth-Operationen
- **VORTEIL:** Weniger Dependencies, einfacheres Deployment

#### 3. Init-Container Pattern
- **NEU:** Docker Compose mit Init-Container-Service
- **NEU:** Garantierte Deployment-Reihenfolge via `depends_on`
- **NEU:** Named Volumes statt bind mounts
- **VORTEIL:** security.json überlebt Container-Restarts

#### 4. Rundeck-Integration
- **NEU:** Vollständige Rundeck-API-Integration
- **NEU:** Automatische Job-Registrierung (Health Check, Backup, Restart)
- **NEU:** Webhook-Receiver für Remote-Trigger
- **NEU:** JSON-Output für Rundeck-Kompatibilität
- **VORTEIL:** Monitoring und Automation und für Kkeck ;) 

#### 5. Modulare Task-Struktur
- **GEÄNDERT:** Auth-Logik auf 4 separate Task-Dateien aufgeteilt anstonsten einfach zu groß ~500 zeilen
- **VORTEIL:** Bessere Wartbarkeit

---

### Geänderte Dateien

#### tasks/main.yml
**Status:** VOLLSTÄNDIG ÜBERARBEITET  
**Änderungen:**
- Task-Reihenfolge geändert: Auth VOR Deployment (Tasks 4-5 vor Task 7)
- Neue Task-Includes: auth_prehash, auth_securityjson, compose_generation
- Rundeck-Integration am Ende hinzugefügt(Default=deaktviert muss mit Angeben werden.)
- security_setup.yml, security_bcrypt.yml, etc. ENTFERNT (durch neue Module ersetzt)

#### defaults/main.yml
**Status:** ERWEITERT  
**Neue Variablen:**
- `solr_compose_dir: "/opt/solr"`
- `solr_config_dir: "{{ solr_compose_dir }}/config"`
- `solr_init_container_timeout: 60`
- `solr_init_container_retries: 5`
- `solr_bcrypt_rounds: 10`
- `rundeck_integration_enabled: false`
- `rundeck_api_url`, `rundeck_api_token`, `rundeck_project_name`
- `rundeck_webhook_enabled`, `rundeck_webhook_secret`

---

### Neue Task-Dateien v1.1 (outtodate)

#### 1. auth_prehash.yml
**Funktion:** Bcrypt-Hashing VOR Container-Deployment  
**Zeilen:** 143  
**Highlights:**
- Idempotenz-Check für security.json
- Hash-Verifikation
- Rundeck-JSON-Output

#### 2. auth_securityjson.yml (Fixed )
**Funktion:** security.json aus Hashes erstellen  
**Zeilen:** 91  
**Highlights:**
- Template-basierte Generierung
- JSON-Syntax-Validierung
- Struktur-Validierung
- Ownership-Prüfung (8983:8983)

#### 3. compose_generation.yml
**Funktion:** docker-compose.yml generieren  
**Zeilen:** 74  
**Highlights:**
- Init-Container-Pattern
- Syntax-Validierung
- .env-Datei-Generierung
- security.json-Existence-Check

#### 4. container_deployment.yml
**Funktion:** Container mit Init-Pattern deployen  
**Zeilen:** 103  
**Highlights:**
- Init-Container-Wait
- security.json-Deployment-Verifikation
- Health-Check
- Auth-Activation-Check

#### 5. auth_validation.yml
**Funktion:** Post-Deployment Auth-Tests  
**Zeilen:** 121  
**Highlights:**
- Alle drei User-Accounts testen
- Authorization-Tests (Admin vs. Support)
- Rundeck-JSON-Output
- Error Reporting

#### 6. auth_persistence.yml
**Funktion:** Credentials speichern  
**Zeilen:** 119  
**Highlights:**
- host_vars-Speicherung
- Backup-Datei in /var/solr
- Rundeck-Credential-Export
- Vault-ready Format (Weis aber nicht ob unser Ansible das kann also kann optional aktiviert werden)

#### 7. preflight_checks.yml
**Funktion:** Pre-Deployment-Validierung  
**Zeilen:** 104  
**Highlights:**
- Docker Compose-Check
- htpasswd-Verfügbarkeit (Removed)
- Port-Conflict-Detection
- Rundeck-kompatibel

#### 8. rundeck_integration.yml
**Funktion:** Rundeck-API-Integration  
**Zeilen:** 107  
**Highlights:**
- Job-Registrierung (Health, Backup, Restart)
- Webhook-Receiver-Setup
- Health-Check-Endpoint
- API-Token-Authentifizierung

---

### Neue Template-Dateien v1.1

#### 1. security.json.j2
**Änderung:** Verwendet pre-hashed Passwörter statt Klartext  
**Zeilen:** 33 oder mehr

#### 2. docker-compose.yml.j2
**NEU:** Compose-Konfiguration mit Init-Container  
**Zeilen:** 58  
**Services:** solr-init, solr  
**Volumes:** Named Volume statt bind mount

#### 3. docker-compose.env.j2
**NEU:** Environment-Variables für Compose  
**Zeilen:** 19

#### 4. rundeck_health_check_job.yml.j2
**NEU:** Rundeck Job-Definition  
**Schedule:** Alle 5 Minuten

#### 5. rundeck_backup_job.yml.j2
**NEU:** Rundeck Job-Definition  
**Schedule:** Täglich 02:00 Uhr

#### 6. rundeck_restart_job.yml.j2
**NEU:** Rundeck Job-Definition  
**Schedule:** Manuell

#### 7. health_check_endpoint.sh.j2
**NEU:** Health-Check-Script  
**Output:** JSON oder Text

#### 8. rundeck_webhook_receiver.sh.j2
**NEU:** Webhook-Receiver-Script  
**Actions:** health, restart, backup

---

### Entfernte Dateien v1.1

- `tasks/security_setup.yml` → Ersetzt durch auth_prehash.yml
- `tasks/security_bcrypt.yml` → Ersetzt durch auth_prehash.yml + auth_securityjson.yml
- `tasks/security_validation.yml` → Ersetzt durch auth_validation.yml
- `tasks/security_persistence.yml` → Ersetzt durch auth_persistence.yml
- `/tmp/generate_solr_security.py` → Python eliminiert

---

### Problemlösung: "Rehashing-Problem" v1.1

#### Vorher (v1.1.5)
```
1. Container startet
2. API-Call: Erstelle User "admin"
3. Solr generiert neuen Salt → neuer Hash
4. Container-Restart
5. security.json weg (kein Volume)
6. Zurück zu Schritt 2 → IMMER neuer Hash → 401-Fehler
```

#### Nachher (v1.1)
```
1. Pre-Hash: htpasswd -nbBC 10 admin "password"
2. Erstelle security.json mit Hash
3. Init-Container: Kopiere security.json nach /var/solr/data
4. Solr startet mit existierender security.json
5. Container-Restart
6. security.json bleibt (Named Volume)
7. Auth funktioniert! → 200 OK (Maybe)
```
#### Nachher (v1.2.1)
```
1. Solr Intern 
2. Erstellelt security.json mit korrektem Hash Verfahren
3. Init-Container: Kopiere security.json nach /var/solr/data
4. Solr startet mit existierender security.json
5. Container-Restart
6. security.json bleibt (Named Volume)
7. Auth  ghet.

---
### Verzeichnisstruktur v1.2.1

###IDK Someting changed


### Verzeichnisstruktur v1.2

```
/opt/solr/
├── config/
│   ├── security.json          # PRE-DEPLOYMENT
│   └── moodle_schema.xml      # NEU in v1.2
├── docker-compose.yml
└── .env

/var/solr/
├── data/                      # NAMED VOLUME
│   └── security.json         # Von Init-Container kopiert
└── backup/

/usr/local/bin/
├── solr_health_check
└── solr_rundeck_webhook
```
---

### Testing

#### Manuelle Verifikation
```bash
# Auth-Test
curl http://localhost:8983/solr/admin/info/system
# Sollte 401 zurückgeben

curl -u admin:PASSWORD http://localhost:8983/solr/admin/info/system
# Sollte 200 zurückgeben

# Restart-Test
docker compose -f /opt/solr/docker-compose.yml restart
sleep 15
curl -u admin:PASSWORD http://localhost:8983/solr/admin/info/system
# Sollte IMMER NOCH 200 zurückgeben (nicht mehr 401!)
```

#### Automated Tests
```bash
ansible-playbook install_solr.yml -i inventory/hosts --tags install-solr-test
```

---

### Performance

- **Deployment-Zeit:** ~3 Minuten (v1.1), ~3-4 Minuten (v1.2.1 mit Moodle-Tests)
- **Init-Container:** <5 Sekunden
- **Idempotenz:** Kein Auth-Recreation bei wiederholter Ausführung

---

### Sicherheit

- Bcrypt mit 10 Rounds
- Credentials in host_vars (Vault-ready)
- Backup-Dateien mit 0400 Permissions
- Keine Klartext-Passwörter in Logs

---

### Eledia Style Guide Konformität

-  Kebab-case für Role-Name
-  Snake_case für Task-Dateien
-  Dictionary-Struktur
-  Rundeck-kompatible JSON-Outputs

---

### Bekannte Limitierungen v1.1

1. Rundeck-Integration erfordert manuelle API-Token-Konfiguration
2. Webhook-Receiver benötigt nginx/Apache für HTTPS-Zugriff
3. Email-Benachrichtigungen erfordern konfigurierte Mail-Relay

---

**Entwickler:** BSC
**Basis:** Apache Solr 9.9.0, Docker Compose v2

---

### Zusammenfassung
Version 1.2.1 ist ein minor release, der:
- default werte anpasst/hinzufügt
- Das Richtige Hash System verwedet

Version 1.2.0 ist ein feature release, der:
- Vollständige Moodle-Integration bietet (Schema + Test-Docs)
- Moodle 4.1 bis 5.0.x unterstützt
- Optional aktivierbare Test-Dokumente bereitstellt

Version 1.1.0 ist ein major release, der:
- Das kritische Rehashing-Problem systematisch löst
- Python-Abhängigkeiten vollständig eliminiert
- Rundeck-Integration für Monitoring bietet
- Code-Qualität und Wartbarkeit verbessert 

Version 1.0 ist major release:
- Internal Testing Shit :) 


---

**Version:** v1.2.1(26102025)
**Datum:** 25.10.2025  
**Task Datein** 17
**Template Datein** 9
**Status:** Testing Ready (Real Data)
