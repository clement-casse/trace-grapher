MERGE (r:Resource{ name: event.process.serviceName })
    ON CREATE SET r += { created: timestamp() }
    ON MATCH SET r += { lastSeen: timestamp() }

MERGE (t:Trace{ id: event.traceId })
    ON CREATE SET t += { created: timestamp() }
    ON MATCH SET t += { lastSeen: timestamp() }

MERGE (s:Span{ id: event.spanId, uniqId: (event.traceId + event.spanId) })
    ON CREATE SET s += { duration: event.duration, startTime: datetime(event.startTime) }
    ON MATCH SET s:Span:Warning

MERGE (o:Operation{ name: event.operationName })
    ON CREATE SET o += { created: timestamp() }
    ON MATCH SET o += { lastSeen: timestamp() }

MERGE (s)-[:FROM_TRACE]->(t)
MERGE (s)-[:MEASURE]->(o)
MERGE (s)-[:EXECUTES_ON]->(r)

WITH event, r, s, t
UNWIND event.process.tags AS processTag
WITH event, r, s, t, processTag
SET r += CASE processTag.vType
    WHEN 'BOOL' THEN apoc.map.fromValues([processTag.key, processTag.vBool])
    WHEN 'INT64' THEN apoc.map.fromValues([processTag.key, processTag.vInt64])
    ELSE apoc.map.fromValues([processTag.key, processTag.vStr])
END

WITH event, s, t
UNWIND event.tags AS tag
WITH event, s, t, tag
SET s += CASE tag.vType
    WHEN 'BOOL' THEN apoc.map.fromValues([tag.key, tag.vBool])
    WHEN 'INT64' THEN apoc.map.fromValues([tag.key, tag.vInt64])
    ELSE apoc.map.fromValues([tag.key, tag.vStr])
END

// WITH s, t
// CALL apoc.date.expireIn(s, 60, 'm')
// CALL apoc.date.expireIn(t, 60, 'm')
