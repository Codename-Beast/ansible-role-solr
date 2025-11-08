# Solr for Moodle - Docker Edition

**Apache Solr 9.9.0 for Moodle with Docker Compose**

> 📦 **Eledia Solution** - Standalone Docker deployment for Apache Solr optimized for Moodle search.

A standalone Docker solution for running Apache Solr optimized for Moodle search. Works on bare systems as long as Docker is installed.

**Author**: Codename-Beast(BSC) (Eledia)
**Version**: 3.5.0

---
##  Known Issues (Minimal)
docker compose maybe not found , buts its a easy fix 
Symlink macht beides verfügbar
```
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo ln -s $(which docker-compose) /usr/libexec/docker/cli-plugins/docker-compose
```
## ✅ Successfully Tested

**Status**: 
**Successfully deployed and tested in production environment**

**Test Environment**:
- **OS**: Linux Tested on(Debian, HC-Cloud)
- **Docker**: 28.5.1
- **Docker Compose**: 2.40.3
- **Solr**: 9.9.0
- **Test Date**: November 7, 2025

**Verified Functionality**:
- ✅ Solr 9.9.0 started and healthy
- ✅ Moodle core created with 24 fields
- ✅ Authentication working (Basic Auth)
- ✅ Document indexing successful
- ✅ Search queries functional
- ✅ All permissions correct (UID 8983)
- ✅ Zero permission errors
- ✅ Zero authentication errors
- ✅ Zero network conflicts

📋 **Full test results and deployment details**: See [CHANGELOG.md v3.5.0](CHANGELOG.md#350---2025-11-07)

---

## 🎯 Features

- ✅ Apache Solr 9.9.0 with Moodle-optimized schema
- ✅ Docker Compose v2 with optional monitoring
- ✅ BasicAuth security with 3 roles (admin, support, customer)
- ✅ Automated backup with cron scheduling
- ✅ Optional Prometheus + Grafana monitoring
- ✅ Health check API
- ✅ Resource limits and optimization
- ✅ Comprehensive management scripts
- ✅ Pre-flight checks (Docker, ports, disk, memory)
- ✅ Works on bare systems (only Docker required)

## 📋 Requirements

- Docker Engine 20.10+
- Docker Compose v2.0+ (both plugin and standalone binary supported)
- 4GB RAM minimum (8GB recommended)
- 20GB disk space
- Linux (Tested: Debian, Ubuntu, Hetzner Cloud)/macOS/Windows with WSL2

### Tested Environments

✅ **Hetzner Cloud**: CX11, CX21, CX31
✅ **Debian**: 10, 11, 12
✅ **Ubuntu**: 20.04, 22.04
✅ **Docker Compose**: Both `docker compose` (plugin) and `docker-compose` (standalone) work

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone <your-repo-url>
cd solr-moodle-docker

# 2. Initialize environment
make init

# 3. Configure (edit .env file - set passwords!)
nano .env

# 4. Generate configuration
make config

# 5. Start Solr (includes preflight checks + permissions setup)
make start

# 6. Create Moodle core
make create-core

# 7. Check health
make health
```

**Note**: `make start` automatically:
- Runs pre-flight checks (Docker, ports, disk, memory)
- Initializes Solr directories with correct permissions (UID 8983)
- Starts all containers

Solr is now running at: http://localhost:8983

## 🏢 Multi-Tenancy (Optional)

**NEW in v3.2.0**: Host multiple isolated search indexes (tenants) within one Solr instance.

Useful for:
- Multiple Moodle instances on one server
- Dev/Staging environments on same infrastructure
- Cost optimization vs. running multiple Solr containers

### Quick Start - Multi-Tenant

```bash
# Create a tenant (generates core + user + RBAC)
make tenant-create TENANT=prod

# List all tenants
make tenant-list

# Backup a tenant
make tenant-backup TENANT=prod

# Delete a tenant (with backup)
make tenant-delete TENANT=prod BACKUP=true
```

**Security**: Each tenant is completely isolated via Solr RBAC:
- ✅ Dedicated Solr core per tenant
- ✅ Unique credentials per tenant
- ✅ Tenants CANNOT access other tenants' data
- ✅ Admin retains full access

**Documentation**: See [MULTI_TENANCY.md](MULTI_TENANCY.md) ([German](MULTI_TENANCY_DE.md))

## ⚙️ Configuration

### Custom Configuration Directory (Optional)

By default, configuration files are stored in `./config` relative to the project directory.

To use a different location, set `SOLR_CONFIG_DIR` in your `.env`:

```bash
# Example: Store configs in a central location
SOLR_CONFIG_DIR=/var/solr-configs/docker/config
```

**What it affects:**
- `make config` generates files to this directory
- Scripts read from this directory
- Docker mounts this directory into containers

**When to use:**
- Central configuration management
- Shared configs across multiple deployments
- Security requirements (e.g., read-only mounted filesystems)

### Environment Variables (.env)

```bash
# Customer / Project Name
CUSTOMER_NAME=moodle_customer

# Solr Configuration
SOLR_VERSION=9.9.0
SOLR_PORT=8983
SOLR_BIND_IP=127.0.0.1
SOLR_HEAP_SIZE=2g

# Authentication (REQUIRED)
SOLR_ADMIN_USER=admin
SOLR_ADMIN_PASSWORD=your_secure_password_here
SOLR_SUPPORT_USER=support
SOLR_SUPPORT_PASSWORD=your_secure_password_here
SOLR_CUSTOMER_USER=customer
SOLR_CUSTOMER_PASSWORD=your_secure_password_here

# Optional: Monitoring
MONITORING_MODE=none          # none, exporter-only, or full
HEALTH_API_PORT=8888

# Optional: Backup
BACKUP_RETENTION_DAYS=30
```

## 📁 Project Structure

```
.
├── docker-compose.yml        # Main orchestration file
├── .env.example             # Environment template
├── Makefile                 # Convenient commands
├── scripts/                      # Management scripts
│   ├── lib/                     # Shared utilities
│   ├── generate-config.sh       # Config generator
│   ├── hash-password.py         # Password hasher
│   ├── health.sh                # Health checker
│   ├── backup.sh                # Backup script
│   ├── init-solr-permissions.sh # Permissions initializer (auto-run)
│   └── setup-secrets.sh         # Docker Secrets setup
├── config/                  # Solr configuration
│   ├── moodle_schema.xml   # Moodle search schema
│   ├── solrconfig.xml      # Solr config
│   └── security.json       # Auth config (generated)
├── lang/                    # Language files
│   ├── stopwords_en.txt    # English stopwords
│   └── stopwords_de.txt    # German stopwords
├── monitoring/              # Optional monitoring stack
│   ├── prometheus/         # Prometheus config
│   ├── grafana/            # Grafana dashboards
│   └── alertmanager/       # Alert configuration
├── data/                    # Solr data (Docker volume)
├── backups/                 # Backup storage
└── logs/                    # Solr logs
```

## 🛠️ Management Commands

All commands via Makefile:

```bash
# Main Operations
make start               # Start all services (auto-runs preflight + permissions)
make init-permissions    # Manually initialize Solr directories (if needed)
make stop                # Stop all services
make restart             # Restart all services
make logs                # Show Solr logs
make health              # Health check
make create-core         # Create Moodle core
make backup              # Backup Solr data
make clean               # Remove containers
make destroy             # Delete EVERYTHING (⚠️ dangerous)

# Monitoring (optional)
make monitoring-up       # Start monitoring stack
make monitoring-down     # Stop monitoring stack
make grafana             # Open Grafana dashboard
make prometheus          # Open Prometheus UI
make metrics             # Show current metrics
```

## 🔐 Security

### Password Hashing

Passwords are hashed using Double SHA-256 with random salt:

```bash
# Generate hash for single password
python3 scripts/hash-password.py "your_password"

# Verify password against hash
python3 scripts/hash-password.py --verify "password" "HASH SALT"

# Generate config (automatically hashes passwords from .env)
./scripts/generate-config.sh
```

### Docker Secrets (Optional)

For enhanced security, use Docker Secrets instead of .env:

```bash
# Setup secrets
./scripts/setup-secrets.sh

# Secrets will be created in .secrets/ directory
# or as Docker Swarm secrets (auto-detected)
```

### User Roles

- **admin**: Full access (schema, config, cores, backups)
- **support**: Read-only + metrics access
- **customer**: Read + update documents

## 📊 Monitoring

### Deployment Modes

```bash
# 1. Minimal (no monitoring)
docker compose up -d

# 2. With remote monitoring (exporter only)
docker compose --profile exporter-only up -d

# 3. With full local monitoring
docker compose --profile monitoring up -d
```

### Monitoring Stack

When using `--profile monitoring`:
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Alertmanager**: http://localhost:9093

Includes:
- 14 pre-configured alert rules
- Grafana dashboard with 10 panels
- Email/MS Teams/Webhook notifications
- 30-day metrics retention

See [MONITORING.md](MONITORING.md) for details.

## 💾 Backup & Restore

### Automated Backup

Enable automated daily backups:

```bash
# Start with backup profile
docker compose --profile backup up -d

# Backups run daily at 2:00 AM
# Retention: 30 days (configurable)
```

### Manual Backup

```bash
# Create backup
make backup

# or directly
./scripts/backup.sh

# Backups are stored in ./backups/
```

### Restore

```bash
# 1. Stop Solr
make stop

# 2. Restore backup
cp -r backups/backup_YYYYMMDD_HHMMSS/data/* data/

# 3. Start Solr
make start
```

## 🔧 Advanced Configuration

### Resource Limits

Edit `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 4g
      cpus: '2.0'
    reservations:
      memory: 2g
      cpus: '0.5'
```

### JVM Tuning

Optimized G1GC settings already configured:

```yaml
environment:
  SOLR_HEAP: 2g
  SOLR_OPTS: >-
    -XX:+UseG1GC
    -XX:G1HeapRegionSize=32m
    -XX:MaxGCPauseMillis=150
    -XX:InitiatingHeapOccupancyPercent=75
```

### Health Check API

A REST API is available for automation:

```bash
# Check health
curl http://localhost:8888/health

# Response
{
  "customer": "moodle_customer",
  "version": "2.3.1",
  "status": "healthy",
  "solr": {
    "available": true,
    "version": "9.9.0"
  },
  "cores": [
    {
      "name": "moodle_customer_core",
      "numDocs": 1234,
      "size": 5242880
    }
  ]
}
```

## 🐛 Troubleshooting

### Common Issues

**Solr won't start**
```bash
# Check logs
docker compose logs solr

# Check if port is in use
lsof -i :8983
```

**Authentication fails**
```bash
# Regenerate config
./scripts/generate-config.sh

# Restart Solr
make restart
```

**Out of memory**
```bash
# Increase heap size in .env
SOLR_HEAP_SIZE=4g

# Restart
make restart
```

### Health Checks

```bash
# Quick health check
make health

# Or manually
./scripts/health.sh

# Check specific endpoint
curl http://localhost:8983/solr/admin/ping
```

## 📈 Performance

### Recommended Settings

| Environment | Heap Size | CPU Cores | RAM Total |
|-------------|-----------|-----------|-----------|
| Development | 1g | 1 | 2GB |
| Small Prod | 2g | 2 | 4GB |
| Medium Prod | 4g | 4 | 8GB |
| Large Prod | 8g | 8 | 16GB |

### Optimization Tips

1. **Increase heap** for large indexes (>10M documents)
2. **Enable monitoring** to track performance
3. **Regular backups** prevent data loss
4. **Update Solr** regularly for security patches

## 🔄 Updating

### Update Solr Version

```bash
# 1. Backup current data
make backup

# 2. Update version in .env
SOLR_VERSION=9.10.0

# 3. Pull new image
docker compose pull

# 4. Restart
make restart
```

### Update Configuration

```bash
# 1. Edit config files
nano config/solrconfig.xml

# 2. Restart Solr
make restart
```

## 🤝 Integration with Moodle

### Moodle Configuration

In Moodle admin settings:

```
Site administration > Plugins > Search > Manage global search

Search engine: Solr
Solr server hostname: <your-server-ip>
Solr port: 8983
Solr index name: <customer>_core
Secure mode: Yes
Solr server username: customer
Solr server password: <customer_password>
```

### Test Connection

```bash
# From Moodle server
curl -u customer:password \
  http://<solr-server>:8983/solr/<customer>_core/admin/ping
```

## 📚 Documentation

- [MONITORING.md](MONITORING.md) - Complete monitoring guide
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [MULTI_TENANCY.md](MULTI_TENANCY.md) - Multi-tenancy guide

## 📝 Version

**Current Version**: 3.5.0 (Docker branch)

See [CHANGELOG.md](CHANGELOG.md) for version history.

## 🛡️ Security Notes

- Always change default passwords
- Use strong passwords (16+ characters)
- Enable HTTPS (use reverse proxy like nginx/traefik)
- Restrict port access (firewall rules)
- Regular security updates
- Monitor access logs
- Run pre-flight checks before deployment

## ⚖️ License

This project follows the same license as Apache Solr (Apache License 2.0).

## 🙋 Support

For issues and questions:
1. Check [Troubleshooting](#-troubleshooting) section
2. Review logs: `docker compose logs`
3. Check health: `make health`
4. Review [MONITORING.md](MONITORING.md)

---

## 👤 Author & Credits

**Author**: Codename-Beast(BSC)
**Organization**: Eledia GmbH
**Project**: Solr for Moodle - Docker Edition
**Version**: 3.5.0

---

**© 2025 Codename-Beast(BSC) & Eledia** - Built with ❤️ for Moodle + Solr
