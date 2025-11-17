#!/bin/bash
# Script to fix Security Panel access issue (SOLR-15825)
# This script updates the security.json in the Solr container with correct permission order

set -e

CONTAINER_NAME="solr_srhcampus"
SECURITY_JSON="/var/solr/data/security.json"

echo "=== Fixing Solr Security Panel Access ==="
echo ""
echo "Step 1: Backup current security.json..."
sudo docker exec $CONTAINER_NAME cp $SECURITY_JSON ${SECURITY_JSON}.backup
echo "✓ Backup created: ${SECURITY_JSON}.backup"
echo ""

echo "Step 2: Creating fixed security.json..."
cat > /tmp/security.json.fixed << 'EOF'
{
  "authentication": {
    "blockUnknown": true,
    "class": "solr.BasicAuthPlugin",
    "credentials": {
      "bs_karlsruhe_admin": "IV0EHq1OnNrfkZMiZoO7oCjCxxzfZKujBfVRRepfh+g= 6dk3inKp09L75HTZbQIqRHMiBkMPXrjd+uyJpjFDaYo=",
      "gym_stuttgart_admin": "IV0EHq1OnNrfkZMiZoO7oCjCxxzfZKujBfVRRepfh+g= k2aDVroLLaGZuSekCWO5XAftbkZnSkmG4lKXt25hH5Q=",
      "gs_heidelberg_admin": "IV0EHq1OnNrfkZMiZoO7oCjCxxzfZKujBfVRRepfh+g= Kb/rMDJcKC4PuNEY4xj5vIQEv2kqC8jTl0iBZf8mMKs=",
      "rs_mannheim_admin": "IV0EHq1OnNrfkZMiZoO7oCjCxxzfZKujBfVRRepfh+g= CnjNs4e53LYf6P7sWRJdaW1FaZZyH1+4FiDRoNwFn2c=",
      "srhcampus_admin": "IV0EHq1OnNrfkZMiZoO7oCjCxxzfZKujBfVRRepfh+g= NYH2VK6zVfAtXoXBdjb0r4fO7uPeF2+i5RmPVBQ5/fU=",
      "srhcampus_global": "IV0EHq1OnNrfkZMiZoO7oCjCxxzfZKujBfVRRepfh+g= z2Z1NrNwE9Q+9yMfK0BKjZw4VEUvqvUH0DfQPWGbO8I=",
      "srhcampus_support": "IV0EHq1OnNrfkZMiZoO7oCjCxxzfZKujBfVRRepfh+g= AygZ7oI0/GV0Hx2IlbzqX+f9nJ3q1zPKJOjRKqJ3KNg="
    },
    "forwardCredentials": false
  },
  "authorization": {
    "class": "solr.RuleBasedAuthorizationPlugin",
    "permissions": [
      { "name": "security-read", "role": "admin" },
      { "name": "security-edit", "role": "admin" },
      { "name": "health-check-ping", "path": "/admin/ping", "role": null },
      { "name": "health-check-detailed", "path": "/admin/health", "role": null },
      { "name": "health-check-simple", "path": "/admin/healthcheck", "role": null },
      { "name": "health-check-cores", "path": "/admin/cores", "role": null },
      {
        "name": "security-panel-access",
        "path": ["/admin/authentication", "/admin/authorization", "/api/cluster/security"],
        "method": ["GET", "POST", "PUT", "DELETE"],
        "role": ["admin"]
      },
      { "name": "all", "role": "admin" },
      { "name": "schema-read", "role": "admin" },
      { "name": "schema-edit", "role": "admin" },
      { "name": "config-read", "role": ["admin", "support"] },
      { "name": "config-edit", "role": "admin" },
      { "name": "core-admin-read", "role": "admin" },
      { "name": "core-admin-edit", "role": "admin" },
      { "name": "collection-admin-read", "role": "admin" },
      { "name": "collection-admin-edit", "role": "admin" },
      { "name": "metrics-read", "role": ["admin", "support"] },
      { "name": "health", "role": ["admin", "support"] },
      {
        "name": "global-moodle-access",
        "path": ["/*"],
        "collection": ["gs_heidelberg", "rs_mannheim", "gym_stuttgart", "bs_karlsruhe"],
        "role": ["moodle"]
      },
      {
        "name": "bs_karlsruhe-update",
        "collection": "bs_karlsruhe",
        "path": "/update/*",
        "role": ["core-admin-bs_karlsruhe", "moodle"]
      },
      {
        "name": "bs_karlsruhe-read",
        "collection": "bs_karlsruhe",
        "path": "/select",
        "role": ["core-admin-bs_karlsruhe", "moodle", "support"]
      },
      {
        "name": "bs_karlsruhe-admin",
        "collection": "bs_karlsruhe",
        "path": "/*",
        "role": "core-admin-bs_karlsruhe"
      },
      {
        "name": "gym_stuttgart-update",
        "collection": "gym_stuttgart",
        "path": "/update/*",
        "role": ["core-admin-gym_stuttgart", "moodle"]
      },
      {
        "name": "gym_stuttgart-read",
        "collection": "gym_stuttgart",
        "path": "/select",
        "role": ["core-admin-gym_stuttgart", "moodle", "support"]
      },
      {
        "name": "gym_stuttgart-admin",
        "collection": "gym_stuttgart",
        "path": "/*",
        "role": "core-admin-gym_stuttgart"
      },
      {
        "name": "gs_heidelberg-update",
        "collection": "gs_heidelberg",
        "path": "/update/*",
        "role": ["core-admin-gs_heidelberg", "moodle"]
      },
      {
        "name": "gs_heidelberg-read",
        "collection": "gs_heidelberg",
        "path": "/select",
        "role": ["core-admin-gs_heidelberg", "moodle", "support"]
      },
      {
        "name": "gs_heidelberg-admin",
        "collection": "gs_heidelberg",
        "path": "/*",
        "role": "core-admin-gs_heidelberg"
      },
      {
        "name": "rs_mannheim-update",
        "collection": "rs_mannheim",
        "path": "/update/*",
        "role": ["core-admin-rs_mannheim", "moodle"]
      },
      {
        "name": "rs_mannheim-read",
        "collection": "rs_mannheim",
        "path": "/select",
        "role": ["core-admin-rs_mannheim", "moodle", "support"]
      },
      {
        "name": "rs_mannheim-admin",
        "collection": "rs_mannheim",
        "path": "/*",
        "role": "core-admin-rs_mannheim"
      }
    ],
    "user-role": {
      "bs_karlsruhe_admin": ["admin", "core-admin-bs_karlsruhe"],
      "gym_stuttgart_admin": ["admin", "core-admin-gym_stuttgart"],
      "gs_heidelberg_admin": ["admin", "core-admin-gs_heidelberg"],
      "rs_mannheim_admin": ["admin", "core-admin-rs_mannheim"],
      "srhcampus_admin": ["admin"],
      "srhcampus_global": ["moodle"],
      "srhcampus_support": ["support"]
    }
  }
}
EOF
echo "✓ Fixed security.json created"
echo ""

echo "Step 3: Copying fixed security.json into container..."
sudo docker cp /tmp/security.json.fixed $CONTAINER_NAME:$SECURITY_JSON
echo "✓ security.json updated in container"
echo ""

echo "Step 4: Restarting Solr container to apply changes..."
sudo docker restart $CONTAINER_NAME
echo "✓ Container restarted"
echo ""

echo "Step 5: Waiting for Solr to be ready..."
sleep 10
echo ""

echo "=== Fix Complete! ==="
echo ""
echo "Changes made:"
echo "  ✓ security-read permission moved BEFORE 'all'"
echo "  ✓ security-edit permission moved BEFORE 'all'"
echo "  ✓ This fixes SOLR-15825 bug"
echo ""
echo "Please test:"
echo "  1. Login: https://srh-ecampus.de.solr.elearning-home.de/solr-admin/"
echo "  2. User: srhcampus_admin"
echo "  3. Navigate to Security panel"
echo ""
echo "The Security Panel should now be accessible!"
echo ""
echo "If you need to rollback:"
echo "  sudo docker exec $CONTAINER_NAME cp ${SECURITY_JSON}.backup $SECURITY_JSON"
echo "  sudo docker restart $CONTAINER_NAME"
