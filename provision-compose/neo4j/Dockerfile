FROM neo4j:3.5

ARG neo4j_streams_release=3.5.4
ARG neo4j_apoc_release=3.5.0.5

WORKDIR ${NEO4J_HOME}

RUN curl -SsL \
        https://github.com/neo4j-contrib/neo4j-streams/releases/download/${neo4j_streams_release}/neo4j-streams-${neo4j_streams_release}.jar \
        > "./plugins/neo4j-streams-${neo4j_streams_release}.jar" \
 && curl -SsL \
        https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${neo4j_apoc_release}/apoc-${neo4j_apoc_release}-all.jar \
        > "./plugins/apoc-${neo4j_apoc_release}-all.jar"