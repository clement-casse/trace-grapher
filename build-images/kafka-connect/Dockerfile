FROM confluentinc/cp-kafka-connect-base:5.3.1

ARG neo4j_streams_release=3.5.4
ARG kafka_connect_neo4j_version=1.0.4

ENV CONNECT_PLUGIN_PATH "/usr/share/java,/tmp/connect-plugins,/usr/share/confluent-hub-components"

WORKDIR /usr/share/confluent-hub-components

RUN set -eux; \
    apt-get update; \
    apt-get install -y \
        unzip \
    ; \
    curl -SsL \
       https://github.com/neo4j-contrib/neo4j-streams/releases/download/${neo4j_streams_release}/neo4j-kafka-connect-neo4j-${kafka_connect_neo4j_version}.zip \
       > neo4j-kafka-connect-neo4j.zip; \
    unzip neo4j-kafka-connect-neo4j.zip; \
    rm -rf neo4j-kafka-connect-neo4j.zip; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /