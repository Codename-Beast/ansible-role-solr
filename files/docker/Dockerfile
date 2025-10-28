# Version: 1.0.0
# Description: Custom Solr image for Moodle integration

FROM solr:9.9.0

# Metadata
LABEL maintainer="Ansible Automation"
LABEL version="1.0.0"
LABEL description="Solr 9.9.0 configured for Moodle"

# Switch to root for installations
USER root

# Install additional tools
RUN apt-get update && \
    apt-get install -y \
        curl \
        wget \
        netcat-openbsd \
        python3 \
        python3-pip \
        jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /opt/solr/server/solr/configsets/moodle && \
    mkdir -p /var/solr/logs && \
    mkdir -p /var/solr/data

# Copy custom configurations if available
# These will be copied by Ansible if they exist
# COPY configs/solrconfig.xml /opt/solr/server/solr/configsets/moodle/conf/
# COPY configs/schema.xml /opt/solr/server/solr/configsets/moodle/conf/

# Set environment variables
ENV SOLR_HEAP="512m" \
    SOLR_JAVA_MEM="-Xms512m -Xmx512m" \
    ENABLE_REMOTE_JMX_OPTS="false" \
    SOLR_LOG_LEVEL="INFO" \
    SOLR_LOGS_DIR="/var/solr/logs"

# Add healthcheck script
COPY --chown=solr:solr healthcheck.sh /opt/healthcheck.sh
RUN chmod +x /opt/healthcheck.sh

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /opt/healthcheck.sh || exit 1

# Switch back to solr user
USER solr

# Expose ports
EXPOSE 8983

# Set working directory
WORKDIR /opt/solr

# Entry point
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]