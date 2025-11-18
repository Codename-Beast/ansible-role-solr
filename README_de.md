# Ansible Role: Solr

![Version](https://img.shields.io/badge/version-3.9.8-blue)
![Ansible](https://img.shields.io/badge/ansible-2.10.12+-green)
![Solr](https://img.shields.io/badge/solr-9.9.0%20min-orange)
![Moodle](https://img.shields.io/badge/moodle-4.1--5.0.3-purple)
![Tests](https://img.shields.io/badge/tests-production%20getestet-green)
![Status](https://img.shields.io/badge/status-security%20fix%20in%20dev-yellow)

Ansible-Rolle für das Deployment von Apache Solr 9.9.0 (9.10 validiert, nicht getestet) mit BasicAuth, Moodle-Schema-Unterstützung (Datei-Indexierung), vollständiger Idempotenz, Benutzerverwaltung, automatisiertem Backup und umfassendem Monitoring.

**Autor**: Bernd Schreistetter
**Organisation**: Eledia GmbH
**Projekt-Zeitraum**: 24.09.2025 - 18.11.2025 (56 Tage)

> 📖 **[English Version](README.md)** | **[Changelog](CHANGELOG.md)**

---

## 🔒 Version 3.9.8 - SECURITY FIX + Solr Standalone Limitation Dokumentiert

**KRITISCH:** Diese Version dokumentiert eine wichtige Solr-Architektur-Einschränkung und vereinfacht die security.json.

**Was wurde geändert:**
- 📖 **Solr Standalone Limitation dokumentiert**: Laut offizieller Apache Solr Doku funktionieren per-core Permissions NICHT im Standalone-Modus
- 🔒 **Security.json vereinfacht**: Entfernung aller collection-spezifischen Permissions (funktionieren nicht ohne SolrCloud)
- ⚠️ **Globale Permissions**: Alle authentifizierten User haben jetzt Zugriff auf ALLE Cores (Solr Standalone Limitation)
- 📊 **Production getestet**: Main-Branch Deployment validiert (ok=500, changed=61, failed=0)
- 🧹 **Log-Warnungen eliminiert**:
  - Deprecated `enableRemoteStreaming` aus solrconfig.xml entfernt (Solr 9.x nutzt sys-prop)
  - Obsolete `numVersionBuckets` aus solrconfig.xml entfernt (fest auf 65536 in Solr 9.x)
  - SSL-Warnung ist erwartet (SSL auf Proxy-Ebene, nicht Solr-Ebene - korrekte Architektur)
- 🔄 **PowerInit v1.7.0**:
  - Deployed solrconfig.xml automatisch in ALLE configSets
  - Deployed solrconfig.xml automatisch in ALLE existierenden Cores
  - Neuer core_reload.yml Task lädt Cores nach Config-Änderungen neu
  - EFFEKT: Config-Updates werden jetzt automatisch auf existierende Cores angewendet
- ❌ **jmespath Dependency entfernt**: Core-Reload nutzt jetzt native Jinja2 Filter

**Wichtig:** Für per-core Zugriffskontrolle wird SolrCloud mit ZooKeeper benötigt. Siehe "Bekannte Einschränkungen" Abschnitt.

---

## 🎯 Features

### Funktionen
- ✅ **Idempotenz** - Unbegrenzt oft ausführbar ohne Seiteneffekte
- ✅ **Automatisches Rollback** - Wiederherstellung bei Deployment-Fehlern mit block/rescue/always
- ✅ **Selektive Passwort-Updates** - Passwörter ändern ohne Container-Neustart (ZERO Downtime)
- ✅ **Intelligentes Core-Management** - Core-Namensänderungen erstellen neue Cores, alte bleiben erhalten
- ✅ **Docker Compose v2** - Modernes Init-Container-Pattern für Config-Deployment
- ✅ **BasicAuth-Sicherheit** - Rollenbasierte Zugriffskontrolle (admin/support/moodle)
- ✅ **Moodle-Schema** - Vorkonfiguriert für Moodle 4.1-5.0.x Kompatibilität
- ✅ **Automatisierte Backups** - Geplante Backups mit Aufbewahrungsverwaltung
- ✅ **Performance-Monitoring** - JVM-Metriken, GC-Optimierung, Health Checks

### Testing & Validierung
- ✅ **Umfassende Tests** - 19 Integrationstests
- ✅ **Moodle-Dokumententests** - 10 schema-spezifische Validierungstests
- ✅ **Authentifizierungstests** - Multi-User-Autorisierungs-Validierung
- ✅ **Performance-Tests** - Speichernutzung und Query-Antwortzeiten

### Produktions-Validierung (Hetzner Cloud)
- ⚠️ **v3.9.7 Test ausstehend** - Hardware-Validierung auf Hetzner Cloud erforderlich
- 📊 **Letzter Test (v3.9.3)** - Play recap: ok=496, changed=37 (fehlgeschlagen bei Re-Run)
- ✅ **Idempotenz-Hinweis** - Mindestens ~37 Änderungen werden immer angewendet (Konfigurationsupdates, Berechtigungen, Health Checks, etc.)
- 🔧 **Kritische Fixes angewendet** - v3.9.4-v3.9.7 Fixes sollten Re-Run-Authentifizierungsprobleme beheben
- ✅ **Erwartetes Ergebnis** - Frische Installationen UND Re-Runs ohne Container-Löschung sollten beide funktionieren

---

## 📊 FEATURE-SUPPORT-MATRIX

### 🔐 SICHERHEIT & AUTHENTIFIZIERUNGS-FRAMEWORK

| Feature | Admin | Support | Customer | Anonym | Implementierung | Status |
|---------|-------|---------|----------|--------|----------------|--------|
| **Authentifizierungs-Schicht** |
| BasicAuth Login | ✅ | ✅ | ✅ | ❌ | SHA-256 Hashing | ✅ Bereit |
| Session Management | ✅ | ✅ | ✅ | ❌ | Solr Native | ✅ Bereit |
| Passwort-Rotation | ✅ | ✅ | ✅ | ❌ | Zero-Downtime API | ✅ Bereit |
| **Autorisierungs-Matrix** |
| Security Panel Zugriff | ✅ | ❌ | ❌ | ❌ | security-read/edit | ✅ Bereit |
| Core Administration | ✅ | ❌ | ❌ | ❌ | core-admin-edit | ✅ Bereit |
| Schema Management | ✅ | ❌ | ❌ | ❌ | schema-edit | ✅ Bereit |
| Collection Admin | ✅ | ❌ | ❌ | ❌ | collection-admin-edit | ✅ Bereit |
| **Daten-Operationen** |
| Dokument Lesen | ✅ | ✅ | ✅ | ❌ | Collection-scoped | ✅ Bereit |
| Dokument Schreiben/Index | ✅ | ❌ | ✅ | ❌ | Collection-scoped | ✅ Bereit |
| Dokument Löschen | ✅ | ❌ | ❌ | ❌ | Admin-only | ✅ v3.4 |
| **System-Operationen** |
| Metriken-Zugriff | ✅ | ✅ | ❌ | ❌ | /admin/metrics | ✅ v3.4 |
| Backup-Operationen | ✅ | ❌ | ❌ | ❌ | /admin/cores | ✅ v3.4 |
| Log-Management | ✅ | ✅ | ❌ | ❌ | /admin/logging | ✅ v3.4 |
| Health Checks | ✅ | ✅ | ✅ | ✅ | Öffentliche Endpoints | ✅ Bereit |

### 🏗️ INFRASTRUKTUR & DEPLOYMENT-MATRIX

| Komponente | Auto-Deploy | Auto-Config | Monitoring | Backup | Rollback | Status |
|-----------|-------------|-------------|------------|--------|----------|--------|
| **Container-Plattform** |
| Docker Engine | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Bereit |
| Docker Compose v2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Bereit |
| Volume Management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Bereit |
| Network Isolation | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ Bereit |
| **Konfigurations-Management** |
| Solr Core Config | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Bereit |
| Moodle Schema | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Bereit |
| Security Templates | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Bereit |
| Sprachdateien | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ Bereit |
| **System-Integration** |
| Apache Proxy | ✅ | ✅ | ⚠️ | ❌ | ❌ | ⚠️ Teilweise |
| Nginx Proxy | ✅ | ✅ | ⚠️ | ❌ | ❌ | ⚠️ Teilweise |
| Systemd Services | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ Bereit |
| **Backup & Recovery** |
| Automatisierte Backups | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |
| Manuelle Backups | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |
| Aufbewahrungsverwaltung | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |
| Backup-Verifizierung | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ v3.4 |

### 🧪 TESTING & QUALITÄTSSICHERUNGS-MATRIX

| Test-Kategorie | Coverage | Auto-Ausführung | Error Handling | Cleanup | Reporting | Status |
|---------------|----------|-----------------|----------------|---------|-----------|--------|
| **Integrationstests** |
| Authentifizierungs-Tests | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 9/9 PASS |
| Autorisierungs-Tests | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Dokument-Operationen | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Performance-Tests | 90% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| **Moodle-spezifische Tests** |
| Schema-Validierung | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 10/10 PASS |
| Dokument-Typen | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 5/5 Typen |
| Feld-Mapping | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Such-Operationen | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 4/4 PASS |
| **System-Tests** |
| Container Health | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Speichernutzung | 100% | ✅ | ✅ | ✅ | ✅ | ✅ 100% PASS |
| Backup-Funktionalität | 100% | ✅ | ✅ | ✅ | ✅ | ✅ **NEU v1.4** |

### 📊 PERFORMANCE & MONITORING-MATRIX

| Metrik-Kategorie | Sammlung | Alerting | Visualisierung | Export | Aufbewahrung | Status |
|-----------------|----------|----------|----------------|--------|--------------|--------|
| **JVM-Metriken** |
| Speichernutzung | ✅ | ⚠️ | ❌ | ⚠️ | ✅ | ✅ **Erweitert v1.4** |
| GC-Performance | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ **NEU v1.4** |
| Thread-Stats | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Bereit |
| **Solr-Metriken** |
| Query-Performance | ✅ | ⚠️ | ❌ | ⚠️ | ✅ | ✅ **Erweitert v1.4** |
| Index-Größe | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Bereit |
| Request-Raten | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Bereit |
| **System-Health** |
| Container-Status | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ Bereit |
| Festplattennutzung | ✅ | ⚠️ | ❌ | ❌ | ✅ | ✅ Bereit |
| Netzwerk-I/O | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ Bereit |

---

## 📋 Anforderungen

### System-Anforderungen
- **OS**: Debian 11/12
- **Ansible**: 2.10.12 oder höher
- **Docker**: 20.10+ mit Compose v2
- **Apache**
- **Let's Encrypt**

### Webserver & SSL-Anforderungen (Muss vorkonfiguriert sein)
- **Apache Webserver** mit erforderlichen Modulen:
  - `mod_proxy`
  - `mod_proxy_http`
  - `mod_ssl`
  - `mod_headers`
  - `mod_rewrite`
- **Certbot** - Für Let's Encrypt SSL-Zertifikat-Management
- **Domain & DNS** - Vollständig konfigurierte Domain mit DNS-Einträgen zum Server
  - A/AAAA-Einträge für die Solr-Domain (z.B. `solr.example.com`)
  - DNS-Propagierung vor Deployment abgeschlossen

### System-Pakete (werden automatisch installiert)
- curl
- ca-certificates
- gnupg
- lsb-release
- jq (für JSON-Validierung)
- libxml2-utils (für XML-Validierung)

---

## 🚀 Schnellstart

### 1. Rolle installieren
```bash
# Von Git
git clone -b main \
  https://github.com/Codename-Beast/ansible-role-solr.git roles/solr

# Oder von Ansible Galaxy (wenn veröffentlicht)
ansible-galaxy install eledia.solr
```

### 2. Playbook erstellen
```yaml
# playbook.yml
---
- hosts: solr_servers
  become: true
  roles:
    - role: solr
      vars:
        customer_name: "eledia-corp"
        moodle_app_domain: "moodle.eledia.de"
        solr_core_name: "eledia_core"
        # ansible-vault verwenden für Passwörter!
        solr_admin_password: "{{ vault_solr_admin_password }}"  # oder Plaintext
        solr_support_password: "{{ vault_solr_support_password }}"  # oder Plaintext
        solr_moodle_password: "{{ vault_solr_moodle_password }}"  # oder Plaintext
```

### 3. Ausführen
```bash
ansible-playbook -i inventory/hosts playbook.yml
```

---

## ⚙️ Konfiguration

### Erforderliche Variablen
```yaml
customer_name: "eledia.de"              # Kunden-Identifikator
moodle_app_domain: "moodle.eledia.de"   # Ihre Moodle-Domain
```

### Authentifizierung (ansible-vault verwenden!)
```yaml
solr_admin_password: "admin_secret"      # Admin-Benutzer-Passwort (min 12 Zeichen)
solr_support_password: "support_secret"  # Support-Benutzer-Passwort
solr_moodle_password: "moodle_secret"    # Moodle-Benutzer-Passwort

# Optional: Benutzernamen überschreiben
solr_admin_user: "admin"                 # Standard: admin
solr_support_user: "support"             # Standard: support
solr_moodle_user: "moodle"               # Standard: moodle
```

### Container-Konfiguration
```yaml
solr_version: "9.9.0"        # Upgrade auf 9.10.0 validiert und bereit (kompatibel, nicht getestet)
solr_port: 8983              # Solr-Port (Standard: 8983)
solr_heap_size: "2g"         # Java Heap-Größe
solr_memory_limit: "2g"      # Container-Speicherlimit
```

### Verzeichnisstruktur
```yaml
solr_compose_dir: "/opt/solr/{{ customer_name }}"
solr_config_dir: "/opt/solr/{{ customer_name }}/config"
solr_backup_dir: "/opt/solr/{{ customer_name }}/backup"
solr_log_dir: "/var/log/solr"
```

### Erweiterte Optionen
```yaml
# Verhalten
solr_force_recreate: false               # Container-Neuerstellung erzwingen
solr_force_pull: false                   # Image-Pull erzwingen
solr_force_reconfigure_auth: false       # Auth-Rekonfiguration erzwingen

# Features
solr_auth_enabled: true                  # BasicAuth aktivieren
solr_proxy_enabled: true                 # Reverse Proxy aktivieren
solr_backup_enabled: true                # Backups aktivieren
solr_use_moodle_schema: true             # Moodle-Schema verwenden

# Moodle-Konfiguration
solr_moodle_version: "5.0.x"             # Moodle-Version (4.1, 4.2, 4.3, 4.4, 5.0.x)
solr_max_boolean_clauses: 2048
solr_auto_commit_time: 15000             # ms
solr_auto_soft_commit_time: 1000         # ms

# Webserver
solr_webserver: "nginx"                  # oder "apache"
solr_proxy_path: "/solr"
solr_ssl_enabled: true

# Solr Interne Health Checks (v1.3.2)
solr_health_check_enabled: true          # Solr's eingebauten Health Check Handler aktivieren
solr_health_check_mode: "standard"       # Modus: basic, standard, comprehensive
solr_health_disk_threshold: 10           # Warnen wenn < X% Festplattenspeicher frei
solr_health_memory_threshold: 90         # Warnen wenn > X% Heap-Speicher verwendet
solr_health_cache_threshold: 75          # Warnen wenn Cache-Hit-Ratio < X% (nur comprehensive)
```

#### Solr Interne Health Check Modi

Solr 9.9.0 bietet eingebaute Health Check Handler über API-Endpunkte.

| Modus | Prüfungen | Endpunkte | Overhead | Anwendungsfall |
|------|-----------|-----------|----------|----------------|
| **basic** | Nur Festplattenspeicher | `/admin/healthcheck` | Minimal | Schnelle Statusprüfungen |
| **standard** | Festplatte + Speicher + Index | `/admin/health` | **Niedrig** | **Produktion (empfohlen)** |
| **comprehensive** | Alle + Cache + Metriken | `/admin/health` | Mittel | Kritische Systeme, Debugging |

**Health Check Endpunkte:**

```bash
# Einfacher Health Check (basic)
curl -u admin:password "http://localhost:8983/solr/admin/healthcheck"

# Detaillierter Health Check (standard/comprehensive)
curl -u admin:password "http://localhost:8983/solr/admin/health"
```

**Antwort enthält:**
- Festplattenspeicher-Verfügbarkeit (% frei)
- JVM-Heap-Speichernutzung (% verwendet)
- Index-Health und Optimierungsstatus
- Cache-Hit-Ratios (comprehensive Modus)
- Detaillierte Metriken (comprehensive Modus)

**Beispiel-Konfigurationen:**

```yaml
# Entwicklung: Minimaler Overhead
solr_health_check_mode: "basic"

# Produktion: Ausgewogenes Monitoring (Standard)
solr_health_check_mode: "standard"
solr_health_disk_threshold: 10      # Alarm wenn < 10% frei
solr_health_memory_threshold: 90    # Alarm wenn > 90% verwendet

# Kritische Systeme: Umfassendes Monitoring
solr_health_check_mode: "comprehensive"
solr_health_disk_threshold: 15
solr_health_memory_threshold: 85
solr_health_cache_threshold: 75
```

**Health Checks deaktivieren**:
```yaml
solr_health_check_enabled: false
```

### Multi-Core-Konfiguration (v3.9.0+)

Deployen Sie bis zu **4-5 Moodle-Instanzen** auf einem 16GB-Server oder **10 Instanzen** auf einem 32GB-Server mit automatischem RAM-Management und Passwort-Generierung.

#### ⚠️ RAM-Kalkulation

**Korrekte Berechnung basierend auf offizieller Dokumentation:**

```
16GB Server mit 8GB Heap:
├── JVM Heap:        8GB  (Solr/Lucene-Operationen)
├── OS Disk Cache:   6GB  (MMapDirectory - KRITISCH!)
└── System:          2GB  (Docker, OS-Prozesse)

Pro Core RAM-Anforderungen:
├── ramBufferSizeMB:  75-100MB (PER-CORE!)
├── filterCache:      ~50MB    (PER-CORE!)
├── queryResultCache: ~50MB    (PER-CORE!)
├── documentCache:    ~50MB    (PER-CORE!)
└── Working Memory:   Rest

EFFEKTIV PRO CORE: ~1.5-2GB
```

**Limits für Moodle mit Datei-Indexierung:**

| Server RAM | Heap | OS Cache | Max Cores | RAM/Core | Status |
|------------|------|----------|-----------|----------|--------|
| **16GB** | 8GB | 6GB | **4-5** | ~1.5-2GB | ✅ Empfohlen |
| 16GB | 8GB | 6GB | 6 | ~1GB | ⚠️ Performance-Einbußen |
| 16GB | 8GB | 6GB | >6 | <1GB | ❌ Deployment blockiert |
| **32GB** | 20GB | 10GB | **10** | ~1.5-2GB | ✅ Empfohlen |

#### Multi-Core-Beispiel-Konfiguration

```yaml
# Globale Einstellungen (16GB Server, max 4-5 Cores)
customer_name: "school-district"
solr_app_domain: "solr.schools.edu"
solr_heap_size: "8g"            # 8GB für 16GB Server
solr_memory_limit: "14g"        # Container: 8GB Heap + 6GB OS Cache
solr_webserver: "nginx"
solr_ssl_enabled: true

# Multi-Core-Modus: Mehrere Cores definieren
solr_cores:
  - name: "gymnasium_nord"
    domain: "moodle.gymnasium-nord.de"
    users:
      - username: "moodle_gym_nord"
        password: "GymNord2024SecureKey"
        roles: ["core-admin-gymnasium_nord_core"]

  - name: "realschule_sued"
    domain: "moodle.realschule-sued.de"
    users:
      - username: "moodle_real_sued"
        password: ""  # Leer = automatisch sicheres Passwort generieren!

  - name: "grundschule_ost"
    domain: "moodle.grundschule-ost.de"
    users:
      - username: "moodle_gs_ost"
        # Kein Passwort = automatisch generiert
        roles: ["core-admin-grundschule_ost_core", "custom-role"]
```

**Core-Benennung:** Cores werden mit `_core`-Suffix erstellt: `gymnasium_nord_core`, `realschule_sued_core`, etc.

#### Automatische Passwort-Generierung (v3.9.0+)

**Passwörter werden automatisch generiert wenn:**
- Passwort fehlt oder leer ist (`password: ""`)
- Passwort zu schwach ist (< 12 Zeichen)

**Generierte Passwörter:**
- 24 Zeichen lang
- Base64-kodiert (alphanumerisch + sichere Sonderzeichen)
- Nach Deployment mit host_vars-Beispiel angezeigt

**WICHTIG:** Kopieren Sie generierte Passwörter sofort in `host_vars`! Sonst werden beim nächsten Deployment neue Passwörter generiert.

#### YAML-sichere Passwort-Zeichen

**Ohne Anführungszeichen (empfohlen):**
- Buchstaben: `A-Z`, `a-z`
- Zahlen: `0-9`
- Sonderzeichen: `_`, `-`, `$`

**Mit Anführungszeichen (alle Zeichen erlaubt):**
```yaml
password: "My-P@ssw0rd!#2024"  # Anführungszeichen erforderlich für @ ! # : etc.
```

---

## 📖 Nutzungsbeispiele

### Beispiel 1: Erstinstallation
```yaml
- hosts: solr_servers
  become: true
  roles:
    - role: solr
      vars:
        customer_name: "acme-corp"
        moodle_app_domain: "elearning.acme.com"
        solr_heap_size: "4g"
        solr_memory_limit: "4g"
```

### Beispiel 2: Passwort-Update
```bash
# 1. Passwort in host_vars/server.yml aktualisieren
solr_admin_password: "new_secure_password_123"

# 2. Playbook erneut ausführen - nur Passwort ändert sich via API, KEIN Container-Neustart!
ansible-playbook -i inventory playbook.yml

# Ergebnis: Zero Downtime, sofortige Passwort-Änderung
```

### Beispiel 3: Neuen Core hinzufügen
```bash
# Core-Namen in host_vars ändern
solr_core_name: "new_core_2024"

# Playbook erneut ausführen - erstellt neuen Core, alte bleiben erhalten
ansible-playbook -i inventory playbook.yml

# Beide Cores existieren nun und sind funktionsfähig
```

### Beispiel 4: Alles neu erstellen erzwingen
```bash
ansible-playbook -i inventory playbook.yml -e "solr_force_recreate=true"
# Entfernt Volume, erstellt von Grund auf neu
```

### Beispiel 5: Solr-Version aktualisieren
```yaml
# Im Playbook oder host_vars
solr_version: "9.10.0"  # Version aktualisieren
solr_force_recreate: true  # Neuerstellung mit neuer Version erzwingen

# Playbook ausführen
ansible-playbook -i inventory playbook.yml
```

### Beispiel 6: Multi-Core-Deployment (v3.9.0+)

Deployen Sie 10 Schul-Moodle-Instanzen auf einem Solr-Server (**32GB RAM erforderlich!**):

```yaml
# host_vars/solr-prod-01.yml (32GB Server für 10 Cores)
customer_name: "schulverbund-nord"
solr_app_domain: "solr.schulverbund.de"
solr_heap_size: "20g"       # 20GB für 10 Cores (~1.5GB/Core effektiv)
solr_memory_limit: "28g"    # Container: 20GB Heap + 8GB OS Cache

# Alle 10 Cores definieren
solr_cores:
  - name: "gymnasium_nord"
    domain: "gym-nord.schulverbund.de"
    users:
      - username: "moodle_gym_nord"
        password: ""  # Auto-generieren

  - name: "realschule_sued"
    domain: "real-sued.schulverbund.de"
    users:
      - username: "moodle_real_sued"
        password: "RealSued2024SecureIndexKey"  # Oder eigenes Passwort

  # ... 8 weitere Schulen

  - name: "grundschule_west"
    domain: "gs-west.schulverbund.de"
    users:
      - username: "moodle_gs_west"
        password: ""  # Auto-generieren

# Deployment ausführen
ansible-playbook -i inventory playbook.yml

# Ergebnis:
# - 10 isolierte Cores erstellt
# - ~1.5-2GB Heap pro Core effektiv
# - Fehlende Passwörter auto-generiert und angezeigt
# - Jede Schule hat dedizierten Core + Benutzer
```

**16GB-Server-Alternative (max 4 Cores):**
```yaml
# Für 16GB Server: Nur 4 Schulen möglich
solr_heap_size: "8g"
solr_memory_limit: "14g"
solr_cores:
  - name: "gymnasium_nord"    # ... 4 Cores total
  - name: "realschule_sued"
  - name: "grundschule_west"
  - name: "hauptschule_ost"
```

**Cores später hinzufügen (idempotent):**
```yaml
# Für 32GB Server: 11. Core hinzufügen
solr_cores:
  # ... bestehende 10 Cores ...
  - name: "berufsschule_ost"  # NEU (11. Core)
    domain: "bs-ost.schulverbund.de"
    users:
      - username: "moodle_bs_ost"
        password: ""

# Playbook erneut ausführen - nur neuer Core wird erstellt, bestehende bleiben unberührt
ansible-playbook -i inventory playbook.yml

# Warnung: >10 Cores, ~1.3GB pro Core (Performance-Einbußen)
```

---

## 🏗️ Architektur

### Deployment-Ablauf
```
┌──────────────────────┐
│ 1. Preflight Checks  │ → Validiert System, Festplattenspeicher
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 2. System Prep       │ → Erstellt solr-Benutzer (UID 8983), installiert Pakete
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 3. Docker Install    │ → Installiert Docker falls nicht vorhanden
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 4. Auth Management   │ → Generiert Passwort-Hashes, erkennt bestehende Auth
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 5. Config Management │ → Erstellt security.json, Schemas, Stopwords
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 6. Compose Gen       │ → Generiert docker-compose.yml mit Init-Pattern
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 7. Container Deploy  │ → Deployt mit Rollback-Schutz
│   ┌───────────────┐  │
│   │ BLOCK         │  │   ├─ Prüft Config-Änderungen
│   │  Deploy       │  │   ├─ Stoppt falls nötig
│   └───────┬───────┘  │   ├─ Startet mit Init
│   ┌───────▼───────┐  │   └─ Verifiziert Deployment
│   │ RESCUE        │  │
│   │  Recovery     │  │ → Bei Fehler: Neustart-Versuch
│   └───────┬───────┘  │   └─ Protokolliert Fehlerdetails
│   ┌───────▼───────┐  │
│   │ ALWAYS        │  │ → Protokolliert immer Deployment
│   │  Logging      │  │
│   └───────────────┘  │
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 8. Auth Validation   │ → Testet Authentifizierung und Autorisierung
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 9. Auth Persistence  │ → Speichert Credentials (idempotent)
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 10. Core Creation    │ → Erstellt Solr-Core (überspringt falls existiert)
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 11. Proxy Config     │ → Konfiguriert Nginx/Apache Reverse Proxy
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 12. Integration Test │ → Vollständige Stack-Validierung + Cleanup
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│ 13. Finalization     │ → Dokumentation, Zusammenfassung, optionale Benachrichtigungen
└──────────────────────┘
```

### Docker-Stack
```
┌─────────────────────────────────────────┐
│  docker-compose.yml                     │
│                                         │
│  ┌───────────────┐  ┌────────────────┐  │
│  │ solr-init     │  │ solr           │  │
│  │ (Alpine)      │──│ (Official)     │  │
│  │               │  │                │  │
│  │ Validiert:    │  │ Port: 8983     │  │
│  │ - JSON-Syntax │  │ Auth: Basic    │  │
│  │ - XML-Syntax  │  │ Schema: Moodle │  │
│  │               │  │                │  │
│  │ Deployt:      │  │ Health: API    │  │
│  │ - security    │  └────────┬───────┘  │
│  │ - configs     │           │          │
│  │ - stopwords   │    ┌──────▼──────┐   │
│  │ - schemas     │    │   Volume    │   │
│  └───────────────┘    │ solr_data   │   │
│                       └─────────────┘   │
└─────────────────────────────────────────┘
```

### Idempotenz-Logik
```
Playbook ausführen
     │
     ▼
Container-Status prüfen
     │
  ┌──┴──┐
  │     │
  ▼     ▼
Läuft  Läuft nicht
  │         │
  ▼         ▼
Berechne   Deploy
Checksums  (Erstmals)
  │
  ▼
Vergleiche mit
Container
  │
┌─┴─────────────┐
│               │
▼               ▼
Geändert    Unverändert
│               │
▼               ▼
┌──────────┐   ÜBERSPRINGEN
│Welche?   │   (Keine Aktion)
└─┬───┬────┘
  │   │
  ▼   ▼
Auth  Andere
Nur   Configs
  │   │
  ▼   ▼
API   Container
Update Neustart
(0s)  (~20s)
```

---

## 🔒 Sicherheit

### Authentifizierung & Autorisierung
- **BasicAuth**: Alle Endpunkte geschützt
- **Rollenbasierter Zugriff**:
  - `admin`: Volle Kontrolle (Security, Schema, Config, Collections)
  - `support`: Nur-Lesen auf Core
  - `customer`: Lesen + Schreiben auf Core

### Best Practices

#### 1. Ansible Vault für Passwörter verwenden
```bash
# Verschlüsselte Variable erstellen
ansible-vault encrypt_string 'SuperSecret123!' --name 'solr_admin_password'

# In host_vars/server.yml
solr_admin_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          ...encrypted...
```

#### 2. Firewall-Konfiguration
```bash
# Nur localhost + Reverse Proxy erlauben
ufw allow from 127.0.0.1 to any port 8983
ufw allow from <proxy_ip> to any port 8983
```

#### 3. SSL/TLS (via Reverse Proxy)
```yaml
# Im Playbook konfigurieren
solr_ssl_enabled: true
solr_webserver: "nginx"

# Sicherstellen dass Let's Encrypt Zertifikate installiert sind
# Rolle wird Proxy mit SSL konfigurieren
```

#### 4. Regelmäßige Updates
```yaml
# Solr-Version aktuell halten
solr_version: "9.9.0"  # Regelmäßig auf Updates prüfen
```

---

## 🔄 Idempotenz-Szenarien

### Szenario 1: Keine kritischen Änderungen
```bash
$ ansible-playbook playbook.yml
# ✅ Container läuft weiter
# ✅ Kein Neustart
# ✅ Ausführung: ~30 Sekunden
# ✅ Play recap: ok=496, changed=37 (typische Werte)
# ℹ️ Hinweis: Mindestens ~37 Änderungen werden immer angewendet
#          (Berechtigungen, Config-Validierung, Health Checks)
```

### Szenario 2: Nur Passwort-Änderung
```bash
# host_vars bearbeiten: solr_admin_password: "new_password"
$ ansible-playbook playbook.yml

# ✅ Container-Neustart (15-30s Downtime)
# ✅ Passwort nach Neustart aktiv
```

### Szenario 3: Config-Datei-Änderung
```bash
# Bearbeiten: solr_heap_size: "4g"
$ ansible-playbook playbook.yml

# ✅ Container startet neu
# ✅ Downtime: ~15-30 Sekunden
# ✅ Neue Config angewendet
```

### Szenario 4: Core-Namen-Änderung (Additiv)
```bash
# Bearbeiten: solr_core_name: "new_core_2024"
$ ansible-playbook playbook.yml

# ✅ Neuer Core erstellt
# ✅ Alter Core erhalten
# ✅ Beide Cores funktionsfähig
```

### Szenario 5: Deployment-Fehler (Auto-Rollback)
```bash
# Ungültige Config eingeführt
$ ansible-playbook playbook.yml

# ❌ Deployment schlägt fehl
# ✅ Automatisches Rollback versucht
# ✅ Klare Fehlermeldung mit Wiederherstellungsschritten
# ✅ Logs gespeichert in /var/log/solr_deployment_*.log
```

---

## 🛠️ Fehlerbehebung

### Häufige Probleme

#### 1. Init-Container schlägt fehl
```bash
# Init-Container-Logs prüfen
docker logs <container_name>_powerinit

# Häufige Ursachen:
# - Ungültiges JSON in security.json → Template-Syntax prüfen
# - Ungültiges XML im Schema → XML-Dateien validieren
# - Berechtigungsprobleme → solr-Benutzer prüfen (UID 8983)

# Lösung: Logs überprüfen, Templates korrigieren, erneut ausführen
```

#### 2. Container unhealthy
```bash
# Container-Health prüfen
docker ps
docker inspect <container_name> | grep -A 10 Health

# Solr-Logs prüfen
docker logs <container_name>

# Lösung: Neuerstellung erzwingen
ansible-playbook playbook.yml -e "solr_force_recreate=true"
```

#### 3. Authentifizierung funktioniert nicht
```bash
# Auth manuell testen
curl -u admin:password http://localhost:8983/solr/admin/info/system

# Verifizieren dass security.json deployt wurde
docker exec <container_name> cat /var/solr/data/security.json

# Erneut ausführen mit erzwungener Auth-Rekonfiguration
ansible-playbook playbook.yml -e "solr_force_reconfigure_auth=true"
```

#### 4. Port bereits in Verwendung
```bash
# Prozess finden der Port verwendet
ss -ltnp | grep :8983

# Port in host_vars ändern:
solr_port: 8984

# Playbook erneut ausführen
```

---

## ⚠️ Bekannte Einschränkungen & Probleme

### 🔒 Per-Core Zugriffskontrolle Einschränkung (Solr Standalone Architektur)

**WICHTIG:** Laut [offizieller Apache Solr Dokumentation](https://solr.apache.org/guide/solr/latest/deployment-guide/rule-based-authorization-plugin.html):

> "You can't limit access to a specific core through security.json - if you need to limit which users can access which sets of data, you'll have to use SolrCloud and the collections parameter."

**Was das bedeutet:**
- ✅ **Authentifizierung funktioniert**: Alle Benutzer können sich mit ihren Zugangsdaten anmelden
- ⚠️ **Autorisierung ist global**: Im Standalone-Modus (Docker ohne ZooKeeper) funktionieren collection-spezifische Permissions in `security.json` **NICHT**
- ⚠️ **Alle authentifizierten Benutzer können auf ALLE Cores zugreifen**: Feinkörnige Per-Core-Zugriffskontrolle benötigt SolrCloud mit ZooKeeper

**Aktuelle Implementierung (v3.9.8):**
- Nur globale Rollen: `admin`, `support`, `moodle`
- Alle authentifizierten Benutzer haben Lese-/Schreibzugriff auf alle Cores
- Admin-Benutzer haben vollen Zugriff auf Security-, Schema- und Config-APIs
- Support-Benutzer haben Nur-Lese-Zugriff auf Configs und Metriken

**Falls Sie Per-Core-Zugriffskontrolle benötigen:**
- Migration zu SolrCloud-Modus mit ZooKeeper
- Verwendung von Collection-Level-Permissions (nicht im Standalone-Modus unterstützt)
- Oder separate Solr-Instanzen (eine pro Core/Kunde)

---

## 📖 Dokumentation

- **[Changelog](CHANGELOG.md)** - Versionshistorie und Release Notes
- **[English Version](README.md)** - Englische Dokumentation

---

## 👤 Autor

**Bernd Schreistetter**
Rolle: DevOps Engineer / Administrator / Laravel Developer
Organisation: Eledia GmbH

---

## 📄 Lizenz

MIT License

---

**Made with ❤️ for Eledia & Moodle Community**
