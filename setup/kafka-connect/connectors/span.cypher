MERGE (t:Trace{ id: event.traceId })
    ON CREATE SET t += { created: timestamp() }
    ON MATCH SET t += { lastSeen: timestamp() }

MERGE (s:Span{ uniqId: (event.traceId + event.spanId) })
    ON CREATE SET s += { duration: event.duration, startTime: datetime(event.startTime) }

MERGE (s)-[:FROM_TRACE]->(t)

WITH event, s
UNWIND event.tags AS tag
WITH s, tag
SET s += CASE tag.vType
    WHEN 'BOOL'  THEN apoc.map.fromValues([tag.key, tag.vBool])
    WHEN 'INT64' THEN apoc.map.fromValues([tag.key, tag.vInt64])
    ELSE              apoc.map.fromValues([tag.key, tag.vStr])
END