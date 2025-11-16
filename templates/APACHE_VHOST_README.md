# Apache VirtualHost Template - Generisch für jede Domain

Diese Apache VirtualHost Template ist **generisch** und funktioniert mit **jeder Domain**.

## Features

✅ **Universell:** Funktioniert mit beliebiger Domain durch Jinja2-Variablen
✅ **Let's Encrypt:** Automatische SSL-Zertifikat Integration
✅ **Docker Reverse Proxy:** Sichere Kommunikation zu Docker Container
✅ **SSL-Awareness:** Setzt X-Forwarded-Proto Header für Solr
✅ **Security Headers:** HSTS, X-Frame-Options, X-XSS-Protection
✅ **WebSocket Support:** Für Solr Admin UI Live-Updates
✅ **Rate Limiting Ready:** Vorbereitet gegen Brute-Force

## Verwendete Variablen

```yaml
solr_app_domain: "beliebige-domain.de"           # Deine Domain
solr_ssl_cert_path: "/etc/letsencrypt/live/..."  # Let's Encrypt Pfad
customer_name: "customer"                         # Kundenname für Logs
solr_port: 8983                                   # Docker Port (Standard)
solr_proxy_path: /solr                            # Proxy Path (Standard)
```

## Beispiele

### Beispiel 1: Test-Server (elearning-home.de)
```yaml
solr_app_domain: srh-ecampus.de.solr.elearning-home.de
solr_ssl_cert_path: /etc/letsencrypt/live/srh-ecampus.de.solr.elearning-home.de
```

### Beispiel 2: Production-Domain
```yaml
solr_app_domain: solr.example.com
solr_ssl_cert_path: /etc/letsencrypt/live/solr.example.com
```

### Beispiel 3: Subdomain
```yaml
solr_app_domain: search.mycompany.org
solr_ssl_cert_path: /etc/letsencrypt/live/search.mycompany.org
```

## Deployment

### Automatisch (via Ansible)
```bash
ansible-playbook playbook.yml -e @host_vars/customer.yml --tags apache-vhost
```

### Manuell
```bash
# 1. Template rendern (via Ansible oder manuell Variablen ersetzen)
# 2. Nach /etc/apache2/sites-available/ kopieren
sudo cp rendered-vhost.conf /etc/apache2/sites-available/customer-solr.conf

# 3. Apache Module aktivieren
sudo a2enmod proxy proxy_http ssl rewrite headers

# 4. Config testen
sudo apache2ctl configtest

# 5. Site aktivieren
sudo a2ensite customer-solr.conf

# 6. Apache neu laden
sudo systemctl reload apache2
```

## SSL-Zertifikat installieren

### Let's Encrypt (Certbot)
```bash
# Nginx:
sudo certbot --nginx -d your-domain.com

# Apache:
sudo certbot --apache -d your-domain.com

# Standalone (ohne Webserver):
sudo certbot certonly --standalone -d your-domain.com
```

### Zertifikat prüfen
```bash
sudo certbot certificates | grep your-domain.com
ls -la /etc/letsencrypt/live/your-domain.com/
```

## Kommunikationsfluss

```
Internet (Port 443 HTTPS)
    ↓
Apache VirtualHost
    ↓ (Reverse Proxy)
    ↓ (X-Forwarded-Proto: https)
    ↓
Docker Container (127.0.0.1:8983 HTTP)
    ↓
Solr (SSL-Aware, generiert HTTPS-URLs)
```

## Sicherheitsfeatures

### Port-Binding
```yaml
ports:
  - "127.0.0.1:8983:8983"  # NUR localhost, NICHT öffentlich!
```
Docker-Container ist **nur von localhost** erreichbar, nicht vom Internet!

### SSL-Headers
```apache
RequestHeader set X-Forwarded-Proto "https"
RequestHeader set X-Forwarded-Port "443"
RequestHeader set X-Forwarded-Host "{{ solr_app_domain }}"
```
Solr "weiß", dass es hinter HTTPS läuft → Generiert HTTPS-URLs!

### Security Headers
```apache
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```

## Troubleshooting

### Problem: SSL-Zertifikat nicht gefunden
```bash
# Zertifikat-Pfad prüfen:
ls -la /etc/letsencrypt/live/your-domain.com/
# Expected: fullchain.pem, privkey.pem

# Wenn nicht vorhanden:
sudo certbot --apache -d your-domain.com
```

### Problem: Proxy-Fehler
```bash
# Module aktiviert?
apache2ctl -M | grep proxy
# Expected: proxy_module, proxy_http_module

# Wenn nicht:
sudo a2enmod proxy proxy_http
sudo systemctl restart apache2
```

### Problem: "Connection refused" zu Docker
```bash
# Docker-Container läuft?
docker ps | grep solr

# Port-Binding korrekt?
docker ps | grep 8983
# Expected: 127.0.0.1:8983->8983/tcp

# Von Host erreichbar?
curl -I http://127.0.0.1:8983/solr/
# Expected: HTTP/1.1 401 (Auth required)
```

### Problem: HTTP-Warnings in Solr WebUI
```bash
# SSL-Environment-Variablen gesetzt?
docker exec solr-customer env | grep SOLR_URL

# Expected:
# SOLR_URL_SCHEME=https
# SOLR_HOST=your-domain.com
# SOLR_PORT=443

# Wenn nicht gesetzt:
# 1. host_vars prüfen: solr_ssl_enabled: true
# 2. Container neu erstellen: docker compose up -d --force-recreate
```

## Testing

### Apache-Proxy testen
```bash
# Von Server aus:
curl -I https://your-domain.com/solr/
# Expected: HTTP/2 401 (Auth required)

# Mit Auth:
curl -u admin:PASSWORD https://your-domain.com/solr/admin/ping
# Expected: {"status":"OK"}
```

### SSL-Test
```bash
# SSL Labs Test:
# https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com

# Oder via openssl:
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### WebUI-Test
```
1. Browser öffnen: https://your-domain.com/solr/
2. Login-Dialog sollte erscheinen
3. Nach Login: Dashboard sollte https:// URLs zeigen (NICHT http://)
```

## Anpassungen

### Custom Port
```yaml
# host_vars:
solr_port: 9983  # Statt 8983

# Docker Compose:
ports:
  - "127.0.0.1:9983:8983"

# Apache automatisch angepasst durch {{ solr_port }}
```

### Custom Path
```yaml
# host_vars:
solr_proxy_path: /search  # Statt /solr

# URL wird dann:
# https://your-domain.com/search/
```

### Rate Limiting aktivieren
```apache
# In VHost Config (auskommentiert):
<Location "{{ solr_proxy_path }}">
    SetOutputFilter RATE_LIMIT
    SetEnv rate-limit 400  # Max 400 KB/s
</Location>

# Apache Module:
sudo a2enmod ratelimit
sudo systemctl restart apache2
```

## Logs

```bash
# Access Logs:
tail -f /var/log/apache2/${customer_name}-solr-ssl-access.log

# Error Logs:
tail -f /var/log/apache2/${customer_name}-solr-ssl-error.log

# Docker Container Logs:
docker logs -f solr-${customer_name}
```

---

**Template-Pfad:** `templates/apache-vhost-solr.conf.j2`
**Generiert:** Apache VirtualHost Config für beliebige Domain
**Kompatibel:** Apache 2.4+, Debian/Ubuntu, RHEL/CentOS
