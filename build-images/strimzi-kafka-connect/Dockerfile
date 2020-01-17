FROM strimzi/kafka:latest-kafka-2.4.0

ARG neo4j_streams_release=3.5.4
ARG kafka_connect_neo4j_version=1.0.4

USER root:root

WORKDIR /opt/kafka/plugins/

RUN set -eux; \
    yum install -y unzip; \
    curl -SsL \
       https://github.com/neo4j-contrib/neo4j-streams/releases/download/${neo4j_streams_release}/neo4j-kafka-connect-neo4j-${kafka_connect_neo4j_version}.zip \
       > neo4j-kafka-connect-neo4j.zip; \
    unzip neo4j-kafka-connect-neo4j.zip; \
    rm -rf neo4j-kafka-connect-neo4j.zip; \
    yum remove -y unzip; \
    yum clean all;

WORKDIR /opt/kafka/

USER 1001
