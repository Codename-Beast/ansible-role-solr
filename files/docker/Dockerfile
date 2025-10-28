
FROM solr:9.9.0

LABEL maintainer="Ansible Automation"
LABEL version="1.0.0"
LABEL description="Solr 9.9.0 configured for Moodle"

USER root

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

RUN mkdir -p /opt/solr/server/solr/configsets/moodle && \
    mkdir -p /var/solr/logs && \
    mkdir -p /var/solr/data


ENV SOLR_HEAP="512m" \
    SOLR_JAVA_MEM="-Xms512m -Xmx512m" \
    ENABLE_REMOTE_JMX_OPTS="false" \
    SOLR_LOG_LEVEL="INFO" \
    SOLR_LOGS_DIR="/var/solr/logs"

COPY --chown=solr:solr healthcheck.sh /opt/healthcheck.sh
RUN chmod +x /opt/healthcheck.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /opt/healthcheck.sh || exit 1

USER solr

EXPOSE 8983

WORKDIR /opt/solr

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]