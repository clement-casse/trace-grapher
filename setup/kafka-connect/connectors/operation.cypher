MERGE (o:Operation{ name: event.operationName })
    ON CREATE SET o += { created: timestamp() }
    ON MATCH SET o += { lastSeen: timestamp() }

MERGE (s:Span{uniqId: (event.traceId + event.spanId) })

MERGE (s)-[:MEASURE]->(o)