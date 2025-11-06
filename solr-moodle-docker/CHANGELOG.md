# Changelog

All notable changes to the Solr Moodle Docker standalone edition.

## [2.0.0] - 2024-11-06

### Added
- Complete standalone Docker setup
- Docker Compose v2 configuration with init container
- Automated configuration generation
- Password hashing utility (Python)
- Management scripts:
  - start.sh - Start services
  - stop.sh - Stop services
  - health.sh - Health monitoring
  - backup.sh - Automated backups
  - create-core.sh - Core creation
  - logs.sh - Log viewing
  - generate-config.sh - Config generation
- Makefile with convenient commands
- Comprehensive README with examples
- Moodle schema (4.1 - 5.0.x compatible)
- Solr 9.9.0 configuration optimized for Moodle
- BasicAuth security with 3 roles (admin, support, customer)
- Health check endpoints (unauthenticated)
- Automated backup with retention management
- Multi-language stopwords (EN, DE)
- Directory structure for data, backups, logs

### Features
- Zero-downtime updates
- Configuration validation (JSON, XML)
- Docker healthcheck integration
- Volume management
- Network isolation
- Memory limits
- Automated config backup
- Role-based access control

### Security
- SHA-256 password hashing
- BasicAuth enforcement
- Public health endpoints
- Protected admin operations
- Credential management via .env

## [1.0.0] - Initial Ansible Role
- Ansible-based deployment
- Not included in standalone edition
