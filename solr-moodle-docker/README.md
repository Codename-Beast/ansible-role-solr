# Eledia Solr 9.9.0 - Moodle-Optimized Docker Edition

**Version**: 2.0.0
**Author**: Bernd Schreistetter
**Target**: Customers who have Docker but NOT Ansible

This is a standalone Docker solution that replicates the full functionality of the `ansible-role-solr` Ansible role, designed for customers who only have Docker/Docker Compose available.

---

## Features

- ✅ **Apache Solr 9.9.0** with BasicAuth security
- ✅ **Automatic password generation** and SHA256 double-hashing
- ✅ **Moodle schema support** (optional)
- ✅ **Config validation** (JSON + XML syntax checks)
- ✅ **Multi-language stopwords** (German + English)
- ✅ **Synonyms and protwords** for enhanced search
- ✅ **Health checks** (Docker + Solr ping)
- ✅ **Role-based access control** (admin/support/customer)
- ✅ **Automatic core creation**
- ✅ **Credential persistence** (saved to /var/solr/credentials.txt)

---

## Quick Start

### 1. Build the Docker image

```bash
cd solr-moodle-docker
docker-compose build
```

### 2. Configure environment

Copy the example environment file and customize:

```bash
cp .env.example .env
nano .env
```

**Important settings**:
- `CUSTOMER_NAME`: Your customer/company name
- `SOLR_CORE_NAME`: Solr core name (default: `moodle`)
- `SOLR_AUTH_ENABLED`: Enable authentication (default: `true`)
- `SOLR_ADMIN_PASSWORD`: Admin password (leave empty to auto-generate)
- `SOLR_USE_MOODLE_SCHEMA`: Enable Moodle schema (default: `false`)

### 3. Start Solr

```bash
docker-compose up -d
```

### 4. View credentials

If passwords were auto-generated, retrieve them:

```bash
docker exec ${CUSTOMER_NAME}_solr cat /var/solr/credentials.txt
```

### 5. Verify deployment

Check logs:

```bash
docker-compose logs -f
```

Test Solr:

```bash
curl http://localhost:8983/solr/admin/ping?wt=json
```

Test with authentication (use credentials from step 4):

```bash
curl -u admin:YOUR_PASSWORD http://localhost:8983/solr/admin/cores?action=STATUS&wt=json
```

---

## Architecture

```
┌─────────────────────────────────────────────┐
│         Eledia Solr Container               │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Entrypoint Script (entrypoint.sh)   │  │
│  │  ├─ Password generation/hashing       │  │
│  │  ├─ Config generation (security.json) │  │
│  │  ├─ Config validation (jq, xmllint)  │  │
│  │  ├─ Solr startup                      │  │
│  │  └─ Core creation                     │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Apache Solr 9.9.0                   │  │
│  │  ├─ BasicAuth enabled                │  │
│  │  ├─ Core: ${SOLR_CORE_NAME}          │  │
│  │  ├─ Moodle schema (optional)         │  │
│  │  └─ Health checks enabled            │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
         │
         ├─ Volume: solr_data (/var/solr)
         │
         └─ Port: 8983 (localhost only)
```

---

## Directory Structure

```
solr-moodle-docker/
├── Dockerfile                    # Main image definition
├── docker-compose.yml            # Container orchestration
├── .env.example                  # Environment template
├── entrypoint.sh                 # Initialization script
├── hash-password.py              # SHA256 password hashing
├── config-templates/             # Configuration templates
│   ├── security.json.template    # BasicAuth configuration
│   ├── solrconfig.xml.template   # Solr configuration
│   ├── moodle_schema.xml.template# Moodle schema (optional)
│   ├── stopwords_de.txt          # German stopwords
│   ├── stopwords_en.txt          # English stopwords
│   └── synonyms.txt              # Search synonyms
└── README.md                     # This file
```

---

## Configuration Reference

### Required Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CUSTOMER_NAME` | Customer/company identifier | `default` |
| `SOLR_CORE_NAME` | Solr core name | `moodle` |

### Authentication Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SOLR_AUTH_ENABLED` | Enable BasicAuth | `true` |
| `SOLR_ADMIN_USER` | Admin username | `admin` |
| `SOLR_ADMIN_PASSWORD` | Admin password | (auto-generated) |
| `SOLR_SUPPORT_USER` | Support username | `support` |
| `SOLR_SUPPORT_PASSWORD` | Support password | (auto-generated) |
| `SOLR_CUSTOMER_USER` | Customer username | `customer` |
| `SOLR_CUSTOMER_PASSWORD` | Customer password | (auto-generated) |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SOLR_USE_MOODLE_SCHEMA` | Enable Moodle schema | `false` |
| `SOLR_PORT` | Port binding | `127.0.0.1:8983` |
| `SOLR_HEAP` | JVM heap size | `512m` |
| `SOLR_MEMORY_LIMIT` | Container memory limit | `1g` |
| `SOLR_LOG_LEVEL` | Log level | `INFO` |

---

## User Roles and Permissions

### Admin Role (`admin` user)
- **Full access** to all Solr operations
- Can modify security settings
- Can edit schema and configuration
- Can perform backups
- Can create/delete collections and cores

### Support Role (`support` user)
- **Read-only access** to data
- Can view metrics and logging
- Can perform health checks
- Cannot modify data or configuration

### Customer Role (`customer` user)
- **Read-only access** to data
- Can query and search
- Can update documents (if configured)
- Cannot access admin functions

---

## Health Checks

### Docker Health Check

The container includes a built-in health check:

```bash
docker ps
```

Look for `healthy` status.

### Manual Health Check

```bash
# Without auth (ping is public)
curl http://localhost:8983/solr/admin/ping?wt=json

# With auth (detailed health)
curl -u admin:PASSWORD http://localhost:8983/solr/admin/health?wt=json
```

---

## Persistence

### Volume: `solr_data`

All Solr data is stored in a Docker volume:

```bash
docker volume ls
docker volume inspect ${CUSTOMER_NAME}_solr_data
```

### Credentials File

Auto-generated passwords are saved to:

```
/var/solr/credentials.txt
```

**Access**:

```bash
docker exec ${CUSTOMER_NAME}_solr cat /var/solr/credentials.txt
```

**IMPORTANT**: Store these credentials securely! The file will be overwritten on container restart if passwords are not provided via environment variables.

---

## Troubleshooting

### View container logs

```bash
docker-compose logs -f solr
```

### Access container shell

```bash
docker exec -it ${CUSTOMER_NAME}_solr bash
```

### Check generated configs

```bash
docker exec ${CUSTOMER_NAME}_solr ls -la /var/solr/data/
docker exec ${CUSTOMER_NAME}_solr cat /var/solr/data/security.json
```

### Restart container

```bash
docker-compose restart solr
```

### Rebuild from scratch

```bash
docker-compose down -v  # WARNING: Deletes data volume!
docker-compose up -d --build
```

---

## Comparison: Ansible Role vs Standalone Docker

| Feature | Ansible Role | Standalone Docker |
|---------|--------------|-------------------|
| **Deployment** | Multi-step playbook | Single docker-compose up |
| **Dependencies** | Ansible 2.10+ | Docker + Docker Compose v2 |
| **Host packages** | Requires apt packages | None (all in container) |
| **Config management** | Jinja2 templates | envsubst templates |
| **Password hashing** | Ansible passlib | Python passlib (in container) |
| **Validation** | Ansible tasks + init-container | Container entrypoint |
| **Complexity** | 15+ task files | 1 Dockerfile + 1 entrypoint |
| **Customization** | Host_vars + group_vars | .env file |

---

## Maintenance

### Update Solr version

Edit `Dockerfile`:

```dockerfile
FROM solr:9.9.1  # Change version
```

Rebuild:

```bash
docker-compose build --no-cache
docker-compose up -d
```

### Update configuration

1. Edit config templates in `config-templates/`
2. Restart container: `docker-compose restart`

### Backup

```bash
# Backup Solr data volume
docker run --rm -v ${CUSTOMER_NAME}_solr_data:/var/solr -v $(pwd):/backup alpine tar czf /backup/solr-backup-$(date +%Y%m%d).tar.gz /var/solr

# Restore
docker run --rm -v ${CUSTOMER_NAME}_solr_data:/var/solr -v $(pwd):/backup alpine tar xzf /backup/solr-backup-YYYYMMDD.tar.gz -C /
```

---

## Security Notes

1. **Always use custom passwords** in production (don't rely on auto-generation)
2. **Store credentials securely** (use password manager or secrets vault)
3. **Bind to localhost only** (`SOLR_PORT=127.0.0.1:8983`) if using reverse proxy
4. **Use HTTPS** in production (configure nginx/apache as reverse proxy)
5. **Regular backups** (automated via cron or backup solution)
6. **Update Solr regularly** (security patches)

---

## Support

For issues with this standalone Docker solution:

1. Check container logs: `docker-compose logs -f`
2. Verify environment variables: `docker-compose config`
3. Test health checks: `curl http://localhost:8983/solr/admin/ping`
4. Check GitHub issues: [ansible-role-solr](https://github.com/Codename-Beast/ansible-role-solr)

---

## License

Same license as the parent Ansible role.

---

## Changelog

### Version 2.0.0 (2025-11-06)
- Initial standalone Docker release
- Replaces full Ansible role functionality
- Auto-generated passwords with SHA256 hashing
- Moodle schema support
- Multi-language stopwords (DE/EN)
- Complete config validation
- Role-based access control
- Health checks and monitoring
