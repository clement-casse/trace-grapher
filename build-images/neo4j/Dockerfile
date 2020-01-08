FROM neo4j:3.5

ARG neo4j_streams_release=3.5.4

WORKDIR ${NEO4J_HOME}/plugins

ENV NEO4JLABS_PLUGINS='["apoc", "graph-algorithms"]'

RUN set -eux; \
    wget https://github.com/neo4j-contrib/neo4j-streams/releases/download/${neo4j_streams_release}/neo4j-streams-${neo4j_streams_release}.jar;

WORKDIR ${NEO4J_HOME}