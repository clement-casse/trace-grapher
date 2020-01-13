MERGE (r:Resource{ name: event.process.serviceName })
    ON CREATE SET r += { created: timestamp() }
    ON MATCH SET r += { lastSeen: timestamp() }

MERGE (s:Span{uniqId: (event.traceId + event.spanId) })

MERGE (s)-[:EXECUTES_ON]->(r)

WITH event, r
UNWIND event.process.tags AS tag
WITH r, tag
SET r += CASE tag.vType
    WHEN 'BOOL'  THEN apoc.map.fromValues([tag.key, tag.vBool])
    WHEN 'INT64' THEN apoc.map.fromValues([tag.key, tag.vInt64])
    ELSE              apoc.map.fromValues([tag.key, tag.vStr])
END