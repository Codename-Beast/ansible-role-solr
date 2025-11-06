# Multi-Tenancy Anleitung

**Version**: 3.2.0
**Zuletzt aktualisiert**: 2025-11-06

---

## Überblick

Diese Solr Docker-Lösung unterstützt **optionale Multi-Tenancy** für das Hosten mehrerer isolierter Suchindizes (Mandanten) innerhalb einer einzigen Solr-Instanz. Jeder Mandant erhält:

- ✅ **Dedizierter Solr Core** - Isolierte Datenspeicherung
- ✅ **Dedizierter Benutzer** - RBAC-erzwungene Zugriffskontrolle
- ✅ **Eindeutige Anmeldedaten** - Keine gemeinsamen Passwörter
- ✅ **Ressourcen-Monitoring** - Metriken pro Mandant in Grafana
- ✅ **Unabhängige Backups** - Backup/Restore pro Mandant

---

## Inhaltsverzeichnis

1. [Wann Multi-Tenancy verwenden](#wann-multi-tenancy-verwenden)
2. [Architektur](#architektur)
3. [Sicherheitsisolierung](#sicherheitsisolierung)
4. [Mandantenverwaltung](#mandantenverwaltung)
5. [Namenskonventionen](#namenskonventionen)
6. [Migrationsleitfaden](#migrationsleitfaden)
7. [Best Practices](#best-practices)
8. [Fehlerbehebung](#fehlerbehebung)

---

## Wann Multi-Tenancy verwenden

### ✅ Multi-Tenancy verwenden bei:

- **Mehrere Moodle-Instanzen**: Sie betreiben mehrere Moodle-Sites auf einem Server
- **Development/Staging/Production**: Separate Umgebungen auf derselben Infrastruktur
- **Abteilungsisolierung**: Verschiedene Abteilungen benötigen isolierte Suchindizes
- **Kostenoptimierung**: Reduzierter Ressourcenverbrauch vs. mehrere Solr-Container
- **Zentrale Verwaltung**: Ein Monitoring/Backup-Stack für alle Mandanten

### ❌ Single-Tenant (Standard) verwenden bei:

- **Eine Anwendung**: Nur ein Moodle/eine Anwendung benötigt Suche
- **Maximale Isolation**: Sie benötigen vollständige Container-Level-Trennung
- **Einfachheit**: Sie wünschen minimale Komplexität
- **Unterschiedliche Solr-Versionen**: Mandanten benötigen unterschiedliche Solr-Versionen

---

## Architektur

### Single-Tenant Modus (Standard)

```
┌─────────────────────────────────────┐
│  Solr Container                     │
│  ┌───────────────────────────────┐  │
│  │  Core: "moodle"               │  │
│  │  Benutzer: "customer_user"    │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Verwendung**: Standard-Deployment, keine spezielle Konfiguration erforderlich.

### Multi-Tenant Modus (Optional)

```
┌───────────────────────────────────────────────────────┐
│  Solr Container                                       │
│  ┌─────────────────┐  ┌─────────────────┐           │
│  │ Core: moodle_t1 │  │ Core: moodle_t2 │  ...      │
│  │ User: t1_customer│ │ User: t2_customer│           │
│  └─────────────────┘  └─────────────────┘           │
│                                                       │
│  Admin-Benutzer: Hat Zugriff auf ALLE Cores         │
└───────────────────────────────────────────────────────┘
```

**Verwendung**: Aktivieren über Mandantenverwaltungs-Scripts (siehe unten).

---

## Sicherheitsisolierung

### RBAC (Role-Based Access Control)

Jeder Mandant ist durch Solrs integriertes RBAC vollständig isoliert:

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

### Isolierungsgarantien

- ✅ **Keine mandantenübergreifenden Abfragen**: `t1_customer` kann `moodle_t2` nicht abfragen
- ✅ **Kein Schema-Zugriff**: Mandanten können keine Schemas anderer Mandanten ändern
- ✅ **Keine Admin-Operationen**: Mandanten können keine Cores löschen/erstellen
- ✅ **Admin-Aufsicht**: `admin_user` behält vollen Zugriff zur Verwaltung

---

## Mandantenverwaltung

### Neuen Mandanten erstellen

```bash
make tenant-create TENANT=tenant1
```

**Was passiert:**
1. Erstellt Solr Core: `moodle_tenant1`
2. Erstellt Benutzer: `tenant1_customer` mit zufälligem sicherem Passwort
3. Konfiguriert RBAC für Isolation
4. Speichert Anmeldedaten in `.env.tenant1`
5. Validiert Erstellung mit Test-Abfrage

**Ausgabe:**
```
✅ Mandant 'tenant1' erfolgreich erstellt!

📋 Verbindungsdetails:
   Core:     moodle_tenant1
   Benutzer: tenant1_customer
   Passwort: <zufälliges-sicheres-passwort>
   URL:      http://localhost:8983/solr/moodle_tenant1

🔐 Anmeldedaten gespeichert in: .env.tenant1
```

### Alle Mandanten auflisten

```bash
make tenant-list
```

**Ausgabe:**
```
📋 Aktive Mandanten:

Mandant-ID   Core-Name        Benutzerkonto      Dokumente    Größe (MB)   Status
-----------  ---------------  -----------------  -----------  -----------  --------
tenant1      moodle_tenant1   tenant1_customer   1.234        45,2         ✅ Aktiv
tenant2      moodle_tenant2   tenant2_customer   5.678        123,4        ✅ Aktiv
```

### Mandanten löschen

**Mit Backup (empfohlen):**
```bash
make tenant-delete TENANT=tenant1 BACKUP=true
```

**Ohne Backup:**
```bash
make tenant-delete TENANT=tenant1
```

**Was passiert:**
1. Erstellt Backup-Snapshot (wenn `BACKUP=true`)
2. Entlädt und löscht Solr Core
3. Entfernt Benutzer aus security.json
4. Bereinigt Datenverzeichnis
5. Archiviert Anmeldedatei

### Mandanten sichern

**Einzelner Mandant:**
```bash
make tenant-backup TENANT=tenant1
```

**Alle Mandanten:**
```bash
make tenant-backup-all
```

**Backup-Speicherort:** `backups/tenant_<name>_<timestamp>.tar.gz`

---

## Namenskonventionen

### Core-Namen

- **Format**: `moodle_<mandanten_id>`
- **Beispiele**: `moodle_tenant1`, `moodle_prod`, `moodle_abt_hr`
- **Regeln**:
  - Nur Kleinbuchstaben
  - Unterstriche verwenden (keine Bindestriche)
  - Max. 50 Zeichen

### Benutzernamen

- **Format**: `<mandanten_id>_customer`
- **Beispiele**: `tenant1_customer`, `prod_customer`, `abt_hr_customer`
- **Regeln**:
  - Entspricht mandanten_id vom Core-Namen
  - Immer mit `_customer` enden
  - Nur Kleinbuchstaben

### Umgebungsdateien

- **Format**: `.env.<mandanten_id>`
- **Beispiele**: `.env.tenant1`, `.env.prod`
- **Inhalt**:
  ```bash
  TENANT_ID=tenant1
  TENANT_CORE=moodle_tenant1
  TENANT_USER=tenant1_customer
  TENANT_PASSWORD=<generiertes-passwort>
  TENANT_URL=http://localhost:8983/solr/moodle_tenant1
  ```

---

## Migrationsleitfaden

### Migration von Single-Tenant zu Multi-Tenant

**Schritt 1: Vorhandene Daten sichern**
```bash
make backup
```

**Schritt 2: Ersten Mandanten aus vorhandenem Core erstellen**
```bash
# Option A: Vorhandenen Core umbenennen
docker exec -it solr_solr_1 solr stop -p 8983
# Manuell data/moodle zu data/moodle_tenant1 umbenennen
# security.json aktualisieren

# Option B: Neuen Mandanten erstellen und Daten migrieren
make tenant-create TENANT=tenant1
# Solr's Index-Replikation oder Export/Import verwenden
```

**Schritt 3: Anwendungskonfiguration aktualisieren**
```bash
# In Ihrer Moodle config.php:
$CFG->solr_server_hostname = 'localhost';
$CFG->solr_server_port = '8983';
$CFG->solr_indexname = 'moodle_tenant1';  # Geändert von 'moodle'
$CFG->solr_server_username = 'tenant1_customer';
$CFG->solr_server_password = '<aus .env.tenant1>';
```

**Schritt 4: Verbindung testen**
```bash
curl -u tenant1_customer:<passwort> \
  'http://localhost:8983/solr/moodle_tenant1/select?q=*:*'
```

---

## Best Practices

### 1. Kapazitätsplanung

**Faustformel:** 10-15 Mandanten pro 16GB RAM Solr-Instanz.

**Mandantenkapazität berechnen:**
```bash
# Durchschnittliche Indexgröße pro Mandant
AVG_INDEX_SIZE_GB=2

# Verfügbarer Speicherplatz
AVAILABLE_DISK_GB=100

# Max. Mandanten (mit 50% Puffer)
MAX_TENANTS=$((AVAILABLE_DISK_GB / AVG_INDEX_SIZE_GB / 2))
# Ergebnis: ~25 Mandanten
```

### 2. Benennungsstrategie

**Aussagekräftige Mandanten-IDs verwenden:**
- ✅ Gut: `prod`, `staging`, `abt_marketing`, `schule_haupt`
- ❌ Schlecht: `t1`, `test123`, `core1`

### 3. Passwort-Management

**Anmeldedaten sicher speichern:**
```bash
# Passwort-Manager oder Secrets-Vault verwenden
# .env.* Dateien nicht in Git committen

# Zu .gitignore hinzufügen:
echo ".env.*" >> .gitignore

# Umgebungsspezifische Vaults verwenden:
# - Produktion: HashiCorp Vault, AWS Secrets Manager
# - Entwicklung: 1Password, Bitwarden
```

### 4. Backup-Strategie

**Automatisierte Mandanten-Backups:**
```bash
# Zu crontab hinzufügen:
0 2 * * * cd /pfad/zu/solr && make tenant-backup-all >> logs/backup.log 2>&1
```

**Aufbewahrungsrichtlinie:**
- Tägliche Backups: 7 Tage
- Wöchentliche Backups: 4 Wochen
- Monatliche Backups: 12 Monate

---

## Fehlerbehebung

### Mandantenerstellung schlägt fehl

**Fehler:** `Core already exists`
```bash
# Vorhandene Cores prüfen
make tenant-list

# Alten Core bei Bedarf löschen
make tenant-delete TENANT=<name>
```

**Fehler:** `Permission denied`
```bash
# Besitzrechte korrigieren
sudo chown -R 8983:8983 data/ logs/
```

### Mandant kann nicht auf Core zugreifen

**Fehler:** `HTTP 401 Unauthorized`
```bash
# Anmeldedaten überprüfen
source .env.tenant1
curl -u "$TENANT_USER:$TENANT_PASSWORD" "$TENANT_URL/select?q=*:*"

# RBAC-Konfiguration prüfen
docker exec solr_solr_1 cat /var/solr/data/security.json | jq '.authorization.permissions'
```

**Fehler:** `HTTP 403 Forbidden`
```bash
# Rollenzuweisung überprüfen
docker exec solr_solr_1 cat /var/solr/data/security.json | jq '.authorization."user-role"'

# Sicherstellen, dass Mandantenrolle Zugriff auf korrekten Core hat
```

### Leistungseinbußen mit mehreren Mandanten

**Symptome:** Langsame Abfragen über alle Mandanten hinweg

**Diagnose:**
```bash
# JVM-Speicher prüfen
curl -u admin:password 'http://localhost:8983/solr/admin/info/system' | \
  jq '.jvm.memory'

# Cache-Trefferquoten pro Core prüfen
curl -u admin:password 'http://localhost:8983/solr/admin/metrics' | \
  jq '.metrics | to_entries[] | select(.key | contains("CACHE")) | .value'
```

**Lösungen:**
1. Heap-Größe erhöhen (50-60% des Gesamtspeichers beibehalten)
2. Cache-Größen pro Mandant optimieren
3. Horizontal skalieren (mehr Solr-Instanzen hinzufügen)
4. Inaktive Mandanten archivieren

---

## Zugehörige Dokumentation

- [README_DE.md](README_DE.md) - Hauptdokumentation
- [RUNBOOK_DE.md](RUNBOOK_DE.md) - Betriebshandbuch
- [MEMORY_TUNING_DE.md](MEMORY_TUNING_DE.md) - Performance-Tuning

---

## Support

**Bug gefunden?** Melden Sie ihn unter: https://github.com/Codename-Beast/ansible-role-solr/issues
**Fragen?** Schauen Sie in den Abschnitt [Fehlerbehebung](#fehlerbehebung) oben.

---

**Version**: 3.2.0
**Lizenz**: MIT
**Betreut von**: Codename-Beast
