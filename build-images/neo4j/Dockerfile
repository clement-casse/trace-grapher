FROM neo4j:3.5

ARG neo4j_streams_release=3.5.4
ARG neo4j_apoc_release=3.5.0.6
ARG neo4j_graphalgo_release=3.5.4.0

WORKDIR ${NEO4J_HOME}/plugins

# ENV NEO4JLABS_PLUGINS='["apoc", "graph-algorithms"]'

RUN set -eux; \
    wget https://github.com/neo4j-contrib/neo4j-streams/releases/download/${neo4j_streams_release}/neo4j-streams-${neo4j_streams_release}.jar; \
    wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${neo4j_apoc_release}/apoc-${neo4j_apoc_release}-all.jar; \
    wget https://github.com/neo4j-contrib/neo4j-graph-algorithms/releases/download/${neo4j_graphalgo_release}/graph-algorithms-algo-${neo4j_graphalgo_release}.jar;

WORKDIR ${NEO4J_HOME}