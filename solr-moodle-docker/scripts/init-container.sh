#!/bin/sh
# Solr Init Container - Configuration Deployment
# Version: 2.2.0

set -e

echo "========================================="
echo "Solr Configuration Deployment v2.2.0"
echo "========================================="

# Install validation tools
echo "[1/5] Installing validation tools..."
apk add --no-cache jq libxml2-utils 2>&1 | grep -v 'fetch\|OK:' || true

# Create directory structure
echo "[2/5] Creating directory structure..."
mkdir -p /var/solr/data /var/solr/data/configs /var/solr/data/lang /var/solr/backup/configs

# Backup existing configs
echo "[3/5] Backing up existing configs..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [ -f /var/solr/data/security.json ]; then
    cp /var/solr/data/security.json /var/solr/backup/configs/security.json.$TIMESTAMP 2>/dev/null || true
fi

# Validate configuration files
echo "[4/5] Validating configuration files..."
validate_file() {
    FILE=$1
    TYPE=$2

    if [ ! -f "$FILE" ]; then
        echo "  ⚠ Skipping $FILE (not found)"
        return 0
    fi

    echo "  ✓ Validating $(basename $FILE)"

    if [ "$TYPE" = "json" ]; then
        if ! jq empty "$FILE" 2>/dev/null; then
            echo "ERROR: Invalid JSON in $FILE"
            return 1
        fi
    elif [ "$TYPE" = "xml" ]; then
        if ! xmllint --noout "$FILE" 2>/dev/null; then
            echo "ERROR: Invalid XML in $FILE"
            return 1
        fi
    fi

    return 0
}

validate_file /config/security.json json || exit 1
validate_file /config/solrconfig.xml xml || exit 1
validate_file /config/moodle_schema.xml xml || exit 1

# Deploy configuration files
echo "[5/5] Deploying configuration files..."
deploy_file() {
    SRC=$1
    DEST=$2

    if [ -f "$SRC" ]; then
        echo "  ✓ Deploying $(basename $SRC)"
        cp "$SRC" "$DEST"
    fi
}

deploy_file /config/security.json /var/solr/data/security.json
deploy_file /config/solrconfig.xml /var/solr/data/configs/solrconfig.xml
deploy_file /config/moodle_schema.xml /var/solr/data/configs/moodle_schema.xml
deploy_file /config/synonyms.txt /var/solr/data/configs/synonyms.txt
deploy_file /config/protwords.txt /var/solr/data/configs/protwords.txt
deploy_file /lang/stopwords.txt /var/solr/data/lang/stopwords.txt
deploy_file /lang/stopwords_de.txt /var/solr/data/lang/stopwords_de.txt
deploy_file /lang/stopwords_en.txt /var/solr/data/lang/stopwords_en.txt

# Set permissions
echo "Setting permissions..."
chown -R 8983:8983 /var/solr
chmod 600 /var/solr/data/security.json 2>/dev/null || true

echo "========================================="
echo "Deployment: SUCCESS"
echo "========================================="
exit 0
