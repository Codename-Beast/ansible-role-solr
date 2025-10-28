#!/bin/bash
# Version: 1.0.0
# Description: Health check script for Solr container

# Check if Solr is responding
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8983/solr/admin/info/system 2>/dev/null)

# Exit codes:
# 0 = healthy
# 1 = unhealthy

if [ "$response" = "200" ]; then
    # Solr is running without authentication
    echo "Solr is healthy (no auth)"
    exit 0
elif [ "$response" = "401" ]; then
    # Solr is running with authentication enabled
    echo "Solr is healthy (auth enabled)"
    exit 0
else
    # Solr is not responding properly
    echo "Solr is unhealthy (HTTP $response)"
    exit 1
fi