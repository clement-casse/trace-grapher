FROM neo4j:4.0

ARG neo4j_apoc_release=4.0.0.0
#ARG neo4j_graphalgo_release=3.5.4.0

WORKDIR ${NEO4J_HOME}/plugins

# ENV NEO4JLABS_PLUGINS='["apoc", "graph-algorithms"]'

RUN set -eux; \
    wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${neo4j_apoc_release}/apoc-${neo4j_apoc_release}-all.jar; 

WORKDIR ${NEO4J_HOME}