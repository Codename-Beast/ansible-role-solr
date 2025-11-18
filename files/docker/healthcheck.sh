#!/bin/bash
# Version: 1.1.0
# Description: Health check script for Solr container
# Changelog v1.1.0:
#   - FIXED: Changed endpoint from /admin/info/system to /admin/ping
#   - REASON: /admin/ping is explicitly allowed without auth in security.json
#   - BENEFIT: Health checks work correctly with BasicAuth enabled

# Check if Solr is responding
# Using /admin/ping because it's explicitly allowed without authentication in security.json
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8983/solr/admin/ping?wt=json 2>/dev/null)

# Exit codes:
# 0 = healthy
# 1 = unhealthy

if [ "$response" = "200" ]; then
    # Solr is running and ping endpoint responds
    echo "Solr is healthy (ping OK)"
    exit 0
else
    # Solr is not responding properly
    echo "Solr is unhealthy (HTTP $response)"
    exit 1
fi