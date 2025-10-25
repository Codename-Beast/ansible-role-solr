# Changelog - Solr Installation Role

## Version 1.1.0 - 15.9.2025

**Maintainer:** Bernd Schreistetter  
**Typ:** Major Feature Release + Bugfix  
**Priorität:** Hoch - Löst kritisches BasicAuth-Problem

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
- **NEU:** htpasswd (apache2-utils) für bcrypt-Hashing
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

### Neue Task-Dateien

#### 1. auth_prehash.yml
**Funktion:** Bcrypt-Hashing VOR Container-Deployment  
**Zeilen:** 143  
**Highlights:**
- Idempotenz-Check für security.json
- Hash-Verifikation
- Rundeck-JSON-Output

#### 2. auth_securityjson.yml
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
- htpasswd-Verfügbarkeit
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

### Neue Template-Dateien

#### 1. security.json.j2
**Änderung:** Verwendet pre-hashed Passwörter statt Klartext  
**Zeilen:** 33

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

### Entfernte Dateien

- `tasks/security_setup.yml` → Ersetzt durch auth_prehash.yml
- `tasks/security_bcrypt.yml` → Ersetzt durch auth_prehash.yml + auth_securityjson.yml
- `tasks/security_validation.yml` → Ersetzt durch auth_validation.yml
- `tasks/security_persistence.yml` → Ersetzt durch auth_persistence.yml
- `/tmp/generate_solr_security.py` → Python eliminiert

---

### Problemlösung: "Rehashing-Problem"

#### Vorher (v1.0)
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

---

### Verzeichnisstruktur v1.1

```
/opt/solr/
├── config/
│   └── security.json          # PRE-DEPLOYMENT
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

- **Deployment-Zeit:** ~3 Minuten
- **Init-Container:** <5 Sekunden
- **Idempotenz:** Kein Auth-Recreation bei wiederholter Ausführung

---

### Sicherheit

- Bcrypt mit 10 Rounds
- Credentials in host_vars (Vault-ready)
- Backup-Dateien mit 0400 Permissions
- Keine Klartext-Passwörter in Logs

---

### Style Guide Konformität

-  Kebab-case für Role-Name
-  Snake_case für Task-Dateien
-  Dictionary-Struktur
-  Rundeck-kompatible JSON-Outputs

---

### Bekannte Limitierungen

1. Rundeck-Integration erfordert manuelle API-Token-Konfiguration
2. Webhook-Receiver benötigt nginx/Apache für HTTPS-Zugriff
3. Email-Benachrichtigungen erfordern konfigurierte Mail-Relay

---

### Nächste Schritte (v1.2 geplant)

- [ ] Multi-Core-Support
- [ ] Solr Cloud-Konfiguration
- [ ] Prometheus-Metrics-Export
- [ ] Grafana-Dashboard-Template
- [ ] Automated Certificate Rotation
- [InProgress] More Rundeck-Integration options
- [InProgress] Standalone Server mit keiner Zwingendenr Moodle Installation. Gebunden (1.1)
---

**Entwicklung:** Bernd Schreistetter  
**Basis:** Apache Solr 9.9.0, Docker Compose v2

---

### Zusammenfassung

Version 1.1.0 ist ein major release, der:
- Das kritische Rehashing-Problem systematisch löst
- Python-Abhängigkeiten vollständig eliminiert
- Rundeck-Integration für  Monitoring bietet
- Code-Qualität und Wartbarkeit verbessert 

---

**Version:** 1.1.0  
**Datum:** 23.10.2025  
**Status:** Testing Ready
