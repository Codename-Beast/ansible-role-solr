#!/bin/bash
# Setup cron for automated backups
# Version: 1.0.0

set -e

: "${BACKUP_ENABLED:=false}"
: "${BACKUP_SCHEDULE:=0 2 * * *}"

if [ "${BACKUP_ENABLED}" = "true" ]; then
    echo "Setting up backup cron job..."
    echo "${BACKUP_SCHEDULE} /opt/eledia/scripts/backup.sh >> /var/solr/logs/backup.log 2>&1" | crontab -
    echo "✓ Backup cron job installed: ${BACKUP_SCHEDULE}"

    # Start cron daemon
    service cron start || /usr/sbin/cron
    echo "✓ Cron daemon started"
else
    echo "Backups disabled (BACKUP_ENABLED=false)"
fi
