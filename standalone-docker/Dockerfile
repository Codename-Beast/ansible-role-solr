# Eledia Solr 9.9.0 - Standalone Docker Image
# Replaces ansible-role-solr for customers without Ansible
# Author: Bernd Schreistetter
# Version: 2.0.0

FROM solr:9.9.0

USER root

# Install required tools for config validation and password hashing
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        jq \
        libxml2-utils \
        python3 \
        python3-pip \
        gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Install Python passlib for SHA256 password hashing (same as Ansible)
RUN pip3 install --no-cache-dir passlib bcrypt

# Create directory structure
RUN mkdir -p /opt/eledia/config-templates \
    && mkdir -p /opt/eledia/scripts \
    && mkdir -p /var/solr/data/configs \
    && mkdir -p /var/solr/data/lang \
    && mkdir -p /var/solr/backup/configs

# Copy configuration templates
COPY config-templates/ /opt/eledia/config-templates/

# Copy initialization scripts
COPY entrypoint.sh /opt/eledia/scripts/entrypoint.sh
COPY init-solr.sh /opt/eledia/scripts/init-solr.sh
COPY hash-password.py /opt/eledia/scripts/hash-password.py

# Make scripts executable
RUN chmod +x /opt/eledia/scripts/*.sh

# Set proper ownership
RUN chown -R solr:solr /var/solr \
    && chown -R solr:solr /opt/eledia

# Switch back to solr user
USER solr

# Set working directory
WORKDIR /var/solr

# Use custom entrypoint
ENTRYPOINT ["/opt/eledia/scripts/entrypoint.sh"]

# Default command (can be overridden)
CMD ["solr-foreground"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=5 --start-period=60s \
    CMD curl -f http://localhost:8983/solr/admin/ping?wt=json || exit 1

# Labels
LABEL maintainer="Bernd Schreistetter <bernd@eledia.de>" \
      version="2.0.0" \
      description="Eledia Solr 9.9.0 with BasicAuth, Moodle schema support, and full config management" \
      org.opencontainers.image.source="https://github.com/Codename-Beast/ansible-role-solr"
