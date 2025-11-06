# Solr Moodle Docker - Standalone Edition

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Solr](https://img.shields.io/badge/solr-9.9.0-orange)
![Moodle](https://img.shields.io/badge/moodle-4.1--5.0.x-purple)
![Docker](https://img.shields.io/badge/docker-compose--v2-blue)

Standalone Docker setup for Apache Solr 9.9.0 optimized for Moodle Global Search. No Ansible required!

## Features

- Apache Solr 9.9.0 with Moodle schema
- BasicAuth security (admin, support, customer roles)
- Automated configuration deployment
- Health monitoring
- Automated backups
- Docker Compose v2
- Simple management scripts
- Zero-downtime updates

## Quick Start

### 1. Prerequisites

- Docker 20.10+
- Docker Compose v2
- Python 3 (for password hashing)
- Make (optional, but recommended)

### 2. Initial Setup

```bash
# Clone or download this directory
cd solr-moodle-docker

# Initialize environment
make init

# Edit .env file with your settings
nano .env

# Generate configuration files
make config

# Start Solr
make start

# Create Moodle core
make create-core
```

### 3. Access Solr

```
Admin UI: http://localhost:8983/solr/#/
API:      http://localhost:8983/solr/

Credentials (from .env):
- Admin:    admin / <your_admin_password>
- Support:  support / <your_support_password>
- Customer: customer / <your_customer_password>
```

## Configuration

### Environment Variables (.env)

```bash
# Customer/Project
CUSTOMER_NAME=mycompany
MOODLE_DOMAIN=moodle.example.com

# Solr Settings
SOLR_VERSION=9.9.0
SOLR_PORT=8983
SOLR_HEAP_SIZE=2g
SOLR_MEMORY_LIMIT=4g

# Authentication
SOLR_ADMIN_PASSWORD=strong_admin_password
SOLR_SUPPORT_PASSWORD=strong_support_password
SOLR_CUSTOMER_PASSWORD=strong_customer_password

# Moodle
MOODLE_VERSION=5.0.x
SOLR_MAX_BOOLEAN_CLAUSES=2048

# Backup
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=7
```

## Management Commands

### Using Makefile (Recommended)

```bash
make help           # Show all available commands
make init           # Create .env from template
make config         # Generate configuration files
make start          # Start Solr
make stop           # Stop Solr
make restart        # Restart Solr
make logs           # Show logs (follow)
make health         # Check health status
make create-core    # Create Moodle core
make backup         # Create backup
make clean          # Remove containers
make destroy        # Remove everything (⚠ DESTRUCTIVE)
```

### Using Scripts Directly

```bash
./scripts/generate-config.sh    # Generate config files
./scripts/start.sh               # Start services
./scripts/stop.sh                # Stop services
./scripts/health.sh              # Health check
./scripts/create-core.sh         # Create core
./scripts/backup.sh              # Create backup
./scripts/logs.sh                # Show logs
```

### Using Docker Compose

```bash
docker compose up -d           # Start
docker compose down            # Stop
docker compose ps              # Status
docker compose logs -f solr    # Logs
```

## Directory Structure

```
solr-moodle-docker/
├── config/                    # Configuration files
│   ├── moodle_schema.xml     # Moodle schema definition
│   ├── solrconfig.xml        # Solr configuration
│   ├── security.json         # Generated auth config
│   ├── stopwords*.txt        # Language files
│   ├── synonyms.txt          # Search synonyms
│   └── protwords.txt         # Protected words
├── scripts/                   # Management scripts
│   ├── generate-config.sh    # Config generator
│   ├── hash-password.py      # Password hasher
│   ├── start.sh              # Start script
│   ├── stop.sh               # Stop script
│   ├── health.sh             # Health check
│   ├── backup.sh             # Backup script
│   ├── create-core.sh        # Core creation
│   └── logs.sh               # Log viewer
├── data/                      # Solr data (auto-created)
├── backups/                   # Backup storage
├── logs/                      # Log files
├── docker-compose.yml         # Service definition
├── .env.example               # Environment template
├── .env                       # Your configuration
├── Makefile                   # Command shortcuts
└── README.md                  # This file
```

## Authentication & Roles

### Role Permissions

| Role     | Read | Write | Delete | Admin | Schema | Backup |
|----------|------|-------|--------|-------|--------|--------|
| admin    | ✅   | ✅    | ✅     | ✅    | ✅     | ✅     |
| support  | ✅   | ❌    | ❌     | ❌    | ❌     | ❌     |
| customer | ✅   | ✅    | ❌     | ❌    | ❌     | ❌     |

### Testing Authentication

```bash
# Admin access
curl -u admin:password \
  "http://localhost:8983/solr/admin/cores?action=STATUS"

# Support access (read-only)
curl -u support:password \
  "http://localhost:8983/solr/mycore/select?q=*:*"

# Customer access (read + write)
curl -u customer:password \
  -H "Content-Type: application/json" \
  -d '[{"id":"doc1","title":"Test"}]' \
  "http://localhost:8983/solr/mycore/update?commit=true"
```

## Core Management

### Create Core

```bash
# Using make
make create-core

# Using script
./scripts/create-core.sh

# Using API
curl -u admin:password \
  "http://localhost:8983/solr/admin/cores?action=CREATE&name=mycore&configSet=_default"
```

### Upload Schema

```bash
curl -u admin:password \
  -X POST \
  -H 'Content-type:application/xml' \
  --data-binary @config/moodle_schema.xml \
  "http://localhost:8983/solr/mycore/schema"
```

### Check Core Status

```bash
curl -u admin:password \
  "http://localhost:8983/solr/admin/cores?action=STATUS&core=mycore"
```

## Backup & Restore

### Create Backup

```bash
# Using make
make backup

# Manual backup
docker exec mycompany_solr solr create_backup \
  -c mycore \
  -d /var/solr/backups \
  -n backup_$(date +%Y%m%d)
```

### Restore Backup

```bash
docker exec mycompany_solr solr restore \
  -c mycore \
  -d /var/solr/backups \
  -n backup_20241106
```

### List Backups

```bash
ls -lh backups/
```

## Health Monitoring

### Basic Health Check

```bash
make health
```

### Manual Checks

```bash
# Ping (no auth required)
curl "http://localhost:8983/solr/admin/ping?wt=json"

# Detailed health (no auth required)
curl "http://localhost:8983/solr/admin/health?wt=json"

# System info (requires auth)
curl -u admin:password \
  "http://localhost:8983/solr/admin/info/system?wt=json"

# Core status (requires auth)
curl -u admin:password \
  "http://localhost:8983/solr/admin/cores?action=STATUS"
```

### Container Health

```bash
# Check status
docker compose ps

# View logs
make logs

# Container stats
docker stats mycompany_solr
```

## Moodle Integration

### Configure Moodle

1. Navigate to: **Site Administration → Plugins → Search → Solr**

2. Configure:
```
Hostname: localhost (or Docker host IP)
Port: 8983
Core: mycompany_core
Username: customer
Password: <your_customer_password>
SSL: No (unless using reverse proxy)
```

3. Test connection and create index

### Indexing Content

```bash
# From Moodle CLI
php admin/cli/search_index.php --force
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
make logs

# Check init container
docker logs mycompany_solr_init

# Validate config
docker run --rm -v ./config:/config alpine:3.20 sh -c \
  "apk add --no-cache jq && jq empty /config/security.json"
```

### Authentication Fails

```bash
# Regenerate config
make config

# Check security.json
cat config/security.json

# Restart services
make restart
```

### Core Creation Fails

```bash
# Check Solr is ready
curl "http://localhost:8983/solr/admin/ping"

# Check logs
make logs

# Try manual creation
./scripts/create-core.sh
```

### Performance Issues

```bash
# Increase heap size in .env
SOLR_HEAP_SIZE=4g
SOLR_MEMORY_LIMIT=8g

# Restart
make restart

# Monitor memory
docker stats mycompany_solr
```

## Updating

### Update Solr Version

```bash
# Edit .env
SOLR_VERSION=9.10.0

# Backup first!
make backup

# Recreate
make clean
make start
```

### Update Configuration

```bash
# Edit config files
nano config/solrconfig.xml

# Regenerate and restart
make config
make restart
```

## Security Best Practices

1. **Strong Passwords**: Use passwords with 16+ characters
2. **Firewall**: Only expose port 8983 to localhost
3. **Reverse Proxy**: Use Nginx/Apache with SSL
4. **Regular Backups**: Enable automated backups
5. **Updates**: Keep Solr version current
6. **Monitoring**: Regular health checks

### Firewall Example

```bash
# UFW (Ubuntu/Debian)
ufw allow from 127.0.0.1 to any port 8983
ufw deny 8983

# iptables
iptables -A INPUT -s 127.0.0.1 -p tcp --dport 8983 -j ACCEPT
iptables -A INPUT -p tcp --dport 8983 -j DROP
```

## Advanced Configuration

### Custom Schema Fields

Edit `config/moodle_schema.xml`:

```xml
<field name="custom_field" type="text_general" indexed="true" stored="true"/>
```

### Custom Request Handler

Edit `config/solrconfig.xml`:

```xml
<requestHandler name="/custom" class="solr.SearchHandler">
  <lst name="defaults">
    <str name="echoParams">explicit</str>
    <str name="wt">json</str>
  </lst>
</requestHandler>
```

### Performance Tuning

```bash
# .env
SOLR_HEAP_SIZE=4g
SOLR_MAX_BOOLEAN_CLAUSES=4096
SOLR_AUTO_COMMIT_TIME=30000
SOLR_AUTO_SOFT_COMMIT_TIME=2000
```

## Development

### Testing Changes

```bash
# Make changes to config
nano config/solrconfig.xml

# Validate
docker run --rm -v ./config:/config alpine:3.20 sh -c \
  "apk add --no-cache libxml2-utils && xmllint --noout /config/solrconfig.xml"

# Apply
make restart
```

### Debug Mode

```bash
# .env
SOLR_LOG_LEVEL=DEBUG

# Restart and watch logs
make restart && make logs
```

## Support & Resources

- [Solr Documentation](https://solr.apache.org/guide/9_9/)
- [Moodle Search Documentation](https://docs.moodle.org/en/Global_search)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## License

MIT License

---

**Made with precision for Moodle deployments**
