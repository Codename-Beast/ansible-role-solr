.PHONY: help init config start stop restart logs health backup create-core clean destroy

# Default target
help:
	@echo "=========================================="
	@echo "Solr Moodle Docker - Available Commands"
	@echo "=========================================="
	@echo "  make init         - Initialize environment (.env file)"
	@echo "  make config       - Generate configuration files"
	@echo "  make start        - Start Solr services"
	@echo "  make stop         - Stop Solr services"
	@echo "  make restart      - Restart Solr services"
	@echo "  make logs         - Show Solr logs (follow)"
	@echo "  make health       - Check Solr health"
	@echo "  make create-core  - Create Moodle core"
	@echo "  make backup       - Create backup of Solr core"
	@echo "  make clean        - Stop and remove containers"
	@echo "  make destroy      - Remove everything (containers, volumes, data)"
	@echo "=========================================="

# Initialize environment
init:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
		echo "✓ Created .env file"; \
		echo "⚠ Please edit .env and set your passwords!"; \
	else \
		echo ".env file already exists"; \
	fi

# Generate configuration files
config:
	@./scripts/generate-config.sh

# Start services
start:
	@./scripts/start.sh

# Stop services
stop:
	@./scripts/stop.sh

# Restart services
restart: stop start

# Show logs
logs:
	@./scripts/logs.sh

# Health check
health:
	@./scripts/health.sh

# Create core
create-core:
	@./scripts/create-core.sh

# Backup
backup:
	@./scripts/backup.sh

# Clean up containers
clean:
	@echo "Stopping and removing containers..."
	@docker compose down
	@echo "✓ Containers removed"

# Destroy everything
destroy:
	@echo "⚠ WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		rm -rf data/* backups/* logs/*; \
		echo "✓ All data destroyed"; \
	else \
		echo "Cancelled"; \
	fi
