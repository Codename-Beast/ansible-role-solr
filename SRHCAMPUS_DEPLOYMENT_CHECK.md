# SRH Campus Deployment - Vollständige Checkliste

## 1. Apache VirtualHost Konfiguration

### Generische Config (funktioniert für JEDE Domain)
Die Apache VHost Template (`templates/apache-vhost-solr.conf.j2`) ist generisch und funktioniert mit jeder Domain durch Jinja2-Variablen.

### Installation & Aktivierung
```bash
# Apache Module aktivieren
sudo a2enmod proxy proxy_http rewrite headers ssl

# VHost Config wird durch Ansible-Role automatisch generiert
# Verwendet folgende Variablen aus host_vars:
# - {{ solr_app_domain }} → Beliebige Domain (z.B. srh-ecampus.de.solr.elearning-home.de)
# - {{ solr_ssl_cert_path }} → Let's Encrypt Pfad für diese Domain
# - {{ customer_name }} → Kunde (z.B. srhcampus)
# - {{ solr_port }} → Docker Port (8983)
# - {{ solr_proxy_path }} → Proxy Path (/solr)

# Manuelle Installation (optional):
# sudo ansible-playbook ... --tags apache-vhost

# Config testen
sudo apache2ctl configtest

# Apache neu laden
sudo systemctl reload apache2
```

### Config-Prüfung
```bash
# Apache Status
sudo systemctl status apache2

# Logs live überwachen
sudo tail -f /var/log/apache2/srhcampus-solr-ssl-access.log
sudo tail -f /var/log/apache2/srhcampus-solr-ssl-error.log

# SSL-Zertifikat prüfen
sudo certbot certificates | grep srh-ecampus.de.solr.elearning-home.de
```

---

## 2. Docker ↔ Bare-Metal Kommunikation

### Port-Binding prüfen
```bash
# Docker Container Port-Mapping
docker ps | grep solr-srhcampus
# Expected: 127.0.0.1:8983->8983/tcp

# Lokaler Zugriff von Host
curl -u srhcampus_admin:PASSWORD http://127.0.0.1:8983/solr/admin/ping
# Expected: {"status":"OK"}

# Firewall-Status (Port 8983 muss NICHT öffentlich sein!)
sudo ufw status | grep 8983
# Expected: KEIN OUTPUT (Port nur über Apache erreichbar)

# Verbindung von Apache zu Docker testen
sudo -u www-data curl -I http://127.0.0.1:8983/solr/
# Expected: HTTP/1.1 401 Unauthorized (Auth required - gut!)
```

### Docker-Netzwerk prüfen
```bash
# Solr Container Netzwerk-Details
docker inspect solr-srhcampus | jq '.[0].NetworkSettings'

# Container erreichbar?
docker exec solr-srhcampus curl -s http://localhost:8983/solr/admin/ping | jq .
# Expected: {"status":"OK"}
```

---

## 3. SSL-Awareness in Solr (Keine HTTP-Warnings!)

### Problem
Solr läuft in Docker auf HTTP (Port 8983), aber ist hinter HTTPS-Proxy.
Ohne SSL-Awareness generiert Solr HTTP-URLs in WebUI → Browser-Warnung!

### Lösung (bereits in docker-compose.yml.j2)
```yaml
environment:
  SOLR_URL_SCHEME: https              # ← Solr generiert https:// URLs
  SOLR_HOST: srh-ecampus.de.solr.elearning-home.de
  SOLR_PORT: 443
```

### Prüfung nach Deployment
```bash
# Environment-Variablen im Container prüfen
docker exec solr-srhcampus env | grep SOLR_URL

# Expected:
# SOLR_URL_SCHEME=https
# SOLR_HOST=srh-ecampus.de.solr.elearning-home.de
# SOLR_PORT=443

# WebUI öffnen und Core-URL prüfen
# Browser: https://srh-ecampus.de.solr.elearning-home.de/solr/
# Core-Link sollte HTTPS sein, NICHT HTTP!
```

### Wenn Warnings bleiben
```bash
# Container neu erstellen mit Force-Recreate
ansible-playbook ... -e "solr_force_recreate=true"

# Oder manuell:
cd /opt/solr/srhcampus
docker compose down
docker compose up -d

# Browser-Cache leeren!
# Chrome/Firefox: Strg+Shift+Delete → Cached Images
```

---

## 4. WebUI Security-Einstellungen: Rechte-Problem

### Problem: "Keine Rechte zum Ändern der Security-Einstellungen"

**Ursachen:**
1. User hat nicht role "admin"
2. security.json fehlt "security-edit" permission
3. Browser hat alten Auth-Token gecached

### Lösung 1: User-Rolle prüfen
```bash
# security.json auf Server prüfen
docker exec solr-srhcampus cat /var/solr/data/security.json | jq .

# Prüfe "user-role" Section:
# "srhcampus_admin": ["admin"]  ← MUSS vorhanden sein!
# "eledia_support": ["admin"]   ← MUSS vorhanden sein!

# Prüfe "permissions" Section:
# { "name": "security-edit", "role": "admin" }  ← MUSS vorhanden sein!
```

### Lösung 2: Credentials prüfen
```bash
# Generierte Credentials abrufen
cat /opt/solr/srhcampus/config/credentials.yml

# WebUI-Login testen mit:
# User: srhcampus_admin
# Pass: (aus credentials.yml)

# NICHT verwenden:
# - srhcampus_support (role "support" - Read-Only!)
# - srhcampus_global (role "moodle" - keine Security-Rechte!)

# NUR diese User haben Security-Edit:
# - srhcampus_admin (role "admin")
# - eledia_support (role "admin")
```

### Lösung 3: Browser-Cache leeren
```bash
# Chrome/Firefox:
# 1. Strg+Shift+Delete
# 2. "Cached Images and Files" auswählen
# 3. "Cookies and other site data" auswählen
# 4. Clear Data
# 5. Browser neu starten
# 6. Neu einloggen mit srhcampus_admin

# Oder Incognito/Private Window verwenden
```

### Lösung 4: Security.json manuell prüfen
```bash
# security.json Template validieren
cat templates/security.json.j2 | grep -A2 "security-edit"

# Expected:
# { "name": "security-edit", "role": "admin" }

# Deployed security.json prüfen
docker exec solr-srhcampus cat /var/solr/data/security.json | jq '.authorization.permissions[] | select(.name == "security-edit")'

# Expected:
# {
#   "name": "security-edit",
#   "role": "admin"
# }
```

### Lösung 5: solr_additional_users Rolle prüfen
```bash
# host_vars/srhcampus.yml prüfen:
# solr_additional_users:
#   - username: eledia_support
#     password: ""
#     roles: ["admin"]  # ← WICHTIG: Muss "admin" sein, nicht "support"!

# Falls falsch, korrigieren und neu deployen:
ansible-playbook ... -e "solr_force_reconfigure_auth=true"
```

---

## 5. Authentifizierung End-to-End Test

### Test 1: Apache → Docker (ohne Auth)
```bash
# Von Server aus (ohne Apache):
curl -I http://127.0.0.1:8983/solr/
# Expected: HTTP/1.1 401 Unauthorized

# Mit Credentials:
curl -u srhcampus_admin:PASSWORD http://127.0.0.1:8983/solr/admin/ping
# Expected: {"status":"OK"}
```

### Test 2: Extern → Apache → Docker (mit SSL)
```bash
# Von externem Client:
curl -I https://srh-ecampus.de.solr.elearning-home.de/solr/
# Expected: HTTP/2 401 (Auth required)

# Mit Credentials:
curl -u srhcampus_admin:PASSWORD https://srh-ecampus.de.solr.elearning-home.de/solr/admin/ping
# Expected: {"status":"OK"}
```

### Test 3: Browser WebUI
```
1. Öffne: https://srh-ecampus.de.solr.elearning-home.de/solr/
2. Login-Prompt sollte erscheinen
3. Eingeben:
   - User: srhcampus_admin
   - Pass: (aus credentials.yml)
4. Erwartung: Solr Dashboard erscheint
5. Prüfe URL-Bar: Sollte https:// sein (NICHT http://)
```

### Test 4: Security-Edit in WebUI
```
1. WebUI öffnen als srhcampus_admin
2. Klick auf "Security" (linkes Menü)
3. Erwartung: Security.json wird angezeigt
4. Klick auf "Edit"
5. Erwartung: Editor öffnet sich (KEINE Fehler-Meldung!)
6. Teständerung:
   - Suche: "blockUnknown": true
   - Ändere temporär zu: "blockUnknown": false
   - Klick "Save"
7. Erwartung: "Success" Meldung
8. Zurücksetzen auf: "blockUnknown": true
```

### Test 5: eledia_support Admin-Rechte
```bash
# eledia_support sollte GLEICHE Rechte wie srhcampus_admin haben

# Test via API:
curl -u eledia_support:PASSWORD \
  https://srh-ecampus.de.solr.elearning-home.de/solr/admin/cores?action=STATUS
# Expected: JSON mit Core-Status

# Test via WebUI:
# Login als eledia_support
# Security-Edit sollte funktionieren!
```

---

## 6. Moodle-Integration Test

### Pro Schule: Solr Global Search konfigurieren

**Grundschule Heidelberg:**
```
Site Administration → Plugins → Search → Manage global search

Server hostname: srh-ecampus.de.solr.elearning-home.de
Port: 443
Solr path: /solr
Solr core: gs_heidelberg_core
Username: gs_heidelberg_moodle
Password: (aus credentials.yml)
Secure mode: Yes (HTTPS aktiviert!)

"Check connection" klicken
Expected: ✅ "Connection successful"
```

### Indexierung testen
```bash
# In Moodle CLI (auf Moodle-Server):
sudo -u www-data php admin/cli/search_index.php --force

# Expected: Keine Fehler, Index wird aufgebaut

# Oder via Moodle WebUI:
# Site Administration → Plugins → Search → Manage global search
# "Index" Tab → "Index all" klicken
```

---

## 7. Troubleshooting Checklist

### Apache
- [ ] Module aktiviert: `proxy`, `proxy_http`, `ssl`, `rewrite`, `headers`
- [ ] VHost Config korrekt: `apache2ctl configtest`
- [ ] VHost aktiviert: `a2ensite srh-ecampus-solr.conf`
- [ ] SSL-Zertifikat vorhanden: `/etc/letsencrypt/live/srh-ecampus.de.solr.elearning-home.de/`
- [ ] Apache läuft: `systemctl status apache2`

### Docker
- [ ] Container läuft: `docker ps | grep solr-srhcampus`
- [ ] Port-Binding: `127.0.0.1:8983->8983/tcp` (NICHT 0.0.0.0!)
- [ ] SSL-Env gesetzt: `docker exec solr-srhcampus env | grep SOLR_URL`
- [ ] Logs OK: `docker logs solr-srhcampus --tail 50`

### SSL-Awareness
- [ ] `SOLR_URL_SCHEME=https` gesetzt
- [ ] `SOLR_HOST=srh-ecampus.de.solr.elearning-home.de` gesetzt
- [ ] `SOLR_PORT=443` gesetzt
- [ ] WebUI generiert HTTPS-URLs (nicht HTTP)
- [ ] Browser zeigt KEINE SSL-Warnings

### Authentifizierung
- [ ] security.json vorhanden: `docker exec solr-srhcampus cat /var/solr/data/security.json`
- [ ] Admin-User in role "admin": `srhcampus_admin`, `eledia_support`
- [ ] security-edit permission für role "admin"
- [ ] Credentials korrekt: `/opt/solr/srhcampus/config/credentials.yml`
- [ ] Login funktioniert (WebUI + API)
- [ ] Security-Edit in WebUI funktioniert

### Moodle
- [ ] Hostname korrekt: `srh-ecampus.de.solr.elearning-home.de`
- [ ] Port: `443` (NICHT 8983!)
- [ ] Secure mode: `Yes`
- [ ] Credentials korrekt (pro Schule)
- [ ] Connection successful
- [ ] Indexierung läuft ohne Fehler

---

## 8. Aktualisierte host_vars

```yaml
# host_vars/srhcampus.yml
customer_name: srhcampus
solr_app_domain: srh-ecampus.de.solr.elearning-home.de

solr_admin_user: srhcampus_admin
solr_admin_password: ""

solr_support_user: srhcampus_support
solr_support_password: ""

solr_moodle_user: srhcampus_global
solr_moodle_password: ""

solr_additional_users:
  - username: eledia_support
    password: ""
    roles: ["admin"]  # VOLLE Admin-Rechte!

solr_cores:
  - name: gs_heidelberg
    domain: gs-heidelberg.srh-ecampus.de
    users:
      - username: gs_heidelberg_admin
        password: ""
        roles: ["core-admin-gs_heidelberg_core"]
      - username: gs_heidelberg_moodle
        password: ""
        roles: ["core-admin-gs_heidelberg_core"]
      - username: gs_heidelberg_readonly
        password: ""
        roles: ["support"]
  - name: rs_mannheim
    domain: rs-mannheim.srh-ecampus.de
    users:
      - username: rs_mannheim_admin
        password: ""
        roles: ["core-admin-rs_mannheim_core"]
      - username: rs_mannheim_moodle
        password: ""
        roles: ["core-admin-rs_mannheim_core"]
      - username: rs_mannheim_readonly
        password: ""
        roles: ["support"]
  - name: gym_stuttgart
    domain: gym-stuttgart.srh-ecampus.de
    users:
      - username: gym_stuttgart_admin
        password: ""
        roles: ["core-admin-gym_stuttgart_core"]
      - username: gym_stuttgart_moodle
        password: ""
        roles: ["core-admin-gym_stuttgart_core"]
      - username: gym_stuttgart_readonly
        password: ""
        roles: ["support"]
  - name: bs_karlsruhe
    domain: bs-karlsruhe.srh-ecampus.de
    users:
      - username: bs_karlsruhe_admin
        password: ""
        roles: ["core-admin-bs_karlsruhe_core"]
      - username: bs_karlsruhe_moodle
        password: ""
        roles: ["core-admin-bs_karlsruhe_core"]
      - username: bs_karlsruhe_readonly
        password: ""
        roles: ["support"]

solr_version: "9.9.0"
solr_max_boolean_clauses: 2048
solr_auto_commit_time: 15000
solr_auto_soft_commit_time: 1000

solr_port: 8983
solr_proxy_path: /solr
moodle_solr_host: srh-ecampus.de.solr.elearning-home.de  # Für Moodle-Server

solr_ssl_enabled: true
solr_ssl_cert_path: "/etc/letsencrypt/live/srh-ecampus.de.solr.elearning-home.de"

solr_backup_enabled: false
solr_log_level: INFO
solr_metrics_enabled: true
solr_create_systemd_service: true
```

---

## 9. Deployment Command

```bash
# Full Deployment
ansible-playbook -i inventory/production playbook.yml \
  -e @host_vars/srhcampus.yml \
  --tags solr

# Force Recreate (wenn SSL-Env fehlt):
ansible-playbook -i inventory/production playbook.yml \
  -e @host_vars/srhcampus.yml \
  -e "solr_force_recreate=true" \
  --tags solr

# Nur Auth neu konfigurieren:
ansible-playbook -i inventory/production playbook.yml \
  -e @host_vars/srhcampus.yml \
  -e "solr_force_reconfigure_auth=true" \
  --tags solr
```

---

## 10. Post-Deployment Validation

```bash
# 1. Container-Status
docker ps | grep solr-srhcampus
docker stats solr-srhcampus --no-stream

# 2. SSL-Awareness
docker exec solr-srhcampus env | grep SOLR_URL

# 3. Apache-Proxy
curl -I https://srh-ecampus.de.solr.elearning-home.de/solr/

# 4. Auth Test
curl -u srhcampus_admin:PASSWORD https://srh-ecampus.de.solr.elearning-home.de/solr/admin/ping

# 5. WebUI Test (Browser)
https://srh-ecampus.de.solr.elearning-home.de/solr/
# Login: srhcampus_admin
# Security → Edit sollte funktionieren!

# 6. Credentials
cat /opt/solr/srhcampus/config/credentials.yml

# 7. Logs
docker logs solr-srhcampus --tail 100
tail -f /var/log/apache2/srhcampus-solr-ssl-access.log
```

---

**Bei Problemen:** Siehe jeweilige Troubleshooting-Section oben! 🔧
